#!/usr/bin/env python3
"""Run a native smoke target without forwarding or saving native tool output."""

import argparse
import json
import os
from pathlib import Path
import queue
import shutil
import signal
import subprocess
import sys
import threading
import time

ROOT = Path(__file__).resolve().parents[1]
MODES = {"ui", "email-login", "oauth-login", "oauth-cancel", "restore", "logout"}
PROVIDERS = {"google", "github", "microsoft", "apple", "none"}
STAGES = {
    "startup", "restore_session", "logout", "open_login", "login_routes",
    "awaiting_native_login", "awaiting_native_cancel", "awaiting_email_login", "complete",
}
CHECKS = {
    "real_app_started", "stored_session_restored", "real_logout_cleared_session",
    "login_route_opened", "platform_providers_visible", "auth_forms_open_and_close",
    "real_provider_attempt_started", "real_provider_login_persisted",
    "provider_cancel_returned_silently", "real_email_attempt_started",
    "real_email_login_persisted",
}
REQUIRED_CHECKS = {
    "ui": {"real_app_started", "login_route_opened", "platform_providers_visible",
           "auth_forms_open_and_close"},
    "email-login": {"real_app_started", "login_route_opened",
                    "real_email_attempt_started", "real_email_login_persisted"},
    "oauth-login": {"real_app_started", "login_route_opened",
                    "real_provider_attempt_started", "real_provider_login_persisted"},
    "oauth-cancel": {"real_app_started", "login_route_opened",
                     "real_provider_attempt_started", "provider_cancel_returned_silently"},
    "restore": {"real_app_started", "stored_session_restored"},
    "logout": {"real_app_started", "real_logout_cleared_session"},
}
FAILURE_PRIORITY = {
    "unknown": 0, "build_failed": 1, "test_failed": 2,
    "driver_connection_failed": 3, "device_unavailable": 4,
    "signing_configuration": 5, "tool_start_failed": 6,
}


def is_enum(value, allowed):
    return isinstance(value, str) and value in allowed


def expected_scope(mode):
    if mode == "email-login":
        return "assisted_email_auth"
    return "assisted_native_auth" if mode.startswith("oauth-") else "in_app_ui"


def safe_record(line, expected_mode, expected_provider):
    """Only rebuild records from fixed, public enums; never relay raw log text."""
    if not is_enum(expected_mode, MODES) or not is_enum(expected_provider, PROVIDERS):
        return None
    for marker in ("LOGIN_SMOKE_PROGRESS ", "LOGIN_SMOKE_RESULT "):
        position = line.find(marker)
        if position < 0:
            continue
        try:
            data = json.loads(line[position + len(marker):])
        except (TypeError, ValueError):
            return None
        if not isinstance(data, dict) or not is_enum(data.get("stage"), STAGES):
            return None
        if marker.startswith("LOGIN_SMOKE_PROGRESS"):
            return {"stage": data["stage"]}
        if (
            data.get("mode") != expected_mode
            or data.get("provider") != expected_provider
            or not is_enum(data.get("platform"), {"ios", "android"})
            or not is_enum(data.get("outcome"), {"passed", "failed"})
            or data.get("scope") != expected_scope(expected_mode)
        ):
            return None
        completed = data.get("completed_checks", [])
        if not isinstance(completed, list) or any(not is_enum(item, CHECKS) for item in completed):
            return None
        if data["outcome"] == "passed" and not REQUIRED_CHECKS[expected_mode].issubset(completed):
            return None
        return {
            "mode": expected_mode,
            "provider": expected_provider,
            "platform": data["platform"],
            "outcome": data["outcome"],
            "scope": data["scope"],
            "build_source": "flutter_drive_debug",
            "native_ui_automated": False,
            "play_signed_verified": False,
            "cold_restart_verified": False,
            "completed_checks": completed,
            "stage": data["stage"],
        }
    return None


def classify_tool_line(line):
    """Classify known patterns into fixed enums without retaining matched text."""
    lowered = line.lower()
    stage = None
    failure = None
    if "waiting for another flutter command to release the startup lock" in lowered:
        stage = "flutter_locked"
    elif any(pattern in lowered for pattern in (
        "running xcode build", "building for ios", "xcode build...",
    )):
        stage = "building_ios"
    elif any(pattern in lowered for pattern in (
        "running gradle task", "building apk", "building app bundle",
    )):
        stage = "building_android"
    elif "automatically signing ios" in lowered:
        stage = "signing"
    elif "installing" in lowered:
        stage = "installing"
    elif any(pattern in lowered for pattern in (
        "connecting to flutter application", "connecting to vm service",
        "waiting for vm service", "dart vm service on", "syncing files to device",
    )):
        stage = "connecting_driver"

    if any(pattern in lowered for pattern in (
        "no profiles for", "requires a provisioning profile",
        "requires a development team", "code signing is required",
        "no signing certificate", "provisioning profile doesn't include",
    )):
        failure = "signing_configuration"
    elif any(pattern in lowered for pattern in (
        "no devices found", "no supported devices connected",
        "could not find a device", "device is not connected",
        "device is locked", "device is not available",
    )):
        failure = "device_unavailable"
    elif any(pattern in lowered for pattern in (
        "failed to connect to the vm service", "error connecting to the service protocol",
        "connection closed before full header", "service protocol connection closed",
        "failed to connect to flutter application", "lost connection to device",
    )):
        failure = "driver_connection_failed"
    elif any(pattern in lowered for pattern in (
        "some tests failed", "failure details:", "test failed",
    )):
        failure = "test_failed"
    elif any(pattern in lowered for pattern in (
        "build failed", "could not build the application", "error launching application",
        "failed to build ios app", "gradle task assembledebug failed",
    )):
        failure = "build_failed"
    return stage, failure


def stop_process_group(process, first_signal=signal.SIGTERM):
    """Stop only this wrapper's newly created child process group."""
    group = process.pid
    for stop_signal, grace in ((first_signal, 5), (signal.SIGTERM, 3), (signal.SIGKILL, 1)):
        try:
            os.killpg(group, stop_signal)
        except ProcessLookupError:
            break
        until = time.monotonic() + grace
        while time.monotonic() < until:
            process.poll()  # Reap the leader while checking any descendants.
            try:
                os.killpg(group, 0)
            except ProcessLookupError:
                return
            time.sleep(0.05)
    try:
        process.wait(timeout=1)
    except subprocess.TimeoutExpired:
        pass


def run_command(command, mode, provider, wall_timeout_seconds):
    try:
        process = subprocess.Popen(
            command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, encoding="utf-8", errors="replace", bufsize=1,
            start_new_session=True,
        )
    except OSError:
        print(json.dumps({"failure_category": "tool_start_failed"}), flush=True)
        return 1
    output = queue.Queue()

    def read_output():
        previous_stage = None
        try:
            for line in process.stdout:
                # Discard all raw text after enum classification.
                record = safe_record(line, mode, provider)
                if record is not None:
                    output.put(record)
                tool_stage, failure = classify_tool_line(line)
                if tool_stage is not None and tool_stage != previous_stage:
                    output.put({"tool_stage": tool_stage})
                    previous_stage = tool_stage
                if failure is not None:
                    output.put({"failure_hint": failure})
        except (OSError, ValueError):
            output.put({"failure_hint": "unknown"})
        finally:
            process.stdout.close()
            output.put(None)

    reader = threading.Thread(target=read_output, daemon=True)
    reader.start()
    result = None
    failure_category = "unknown"
    reader_done = False
    last_progress = time.monotonic()
    deadline = last_progress + wall_timeout_seconds
    try:
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                stop_process_group(process)
                print(json.dumps({"failure_category": "wall_timeout"}), flush=True)
                print("Device smoke deadline reached; its child process group was stopped.", flush=True)
                return 124
            if reader_done and process.poll() is not None:
                break
            try:
                record = output.get(timeout=min(15, remaining))
            except queue.Empty:
                if time.monotonic() - last_progress >= 30:
                    print("Flutter is still preparing or running the device test.", flush=True)
                    last_progress = time.monotonic()
                continue
            if record is None:
                reader_done = True
                continue
            if "failure_hint" in record:
                hint = record["failure_hint"]
                if FAILURE_PRIORITY[hint] > FAILURE_PRIORITY[failure_category]:
                    failure_category = hint
            elif "outcome" in record:
                result = record
            else:
                print(json.dumps(record, sort_keys=True), flush=True)
            last_progress = time.monotonic()
        code = process.returncode
    except KeyboardInterrupt:
        stop_process_group(process, first_signal=signal.SIGINT)
        print("Device smoke interrupted; no successful result recorded.", flush=True)
        return 130

    if code or result is None or result["outcome"] != "passed":
        if result is not None:
            result["outcome"] = "failed"
            print(json.dumps(result, sort_keys=True), flush=True)
            if failure_category == "unknown":
                failure_category = "test_failed"
        print(json.dumps({"failure_category": failure_category}), flush=True)
        print("No passing device result verified. Check device state and the reported stage.", flush=True)
        return 1
    print(json.dumps(result, sort_keys=True), flush=True)
    print("Selected smoke mode passed. Native prompts, Play signing and a cold restart require separate evidence.")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", required=True, help="Flutter device identifier")
    parser.add_argument("--mode", choices=sorted(MODES), default="ui")
    parser.add_argument("--provider", choices=sorted(PROVIDERS - {"none"}))
    parser.add_argument("--timeout-seconds", type=int, default=240)
    parser.add_argument("--wall-timeout-seconds", type=int, default=1200,
                        help="Total build/install/test deadline, including native waits")
    parser.add_argument("--flutter", help="Path to the configured Flutter executable")
    args = parser.parse_args()
    assisted = args.mode.startswith("oauth-")
    if assisted != bool(args.provider):
        parser.error("Only OAuth modes require --provider.")
    if not 30 <= args.timeout_seconds <= 600:
        parser.error("The assisted timeout must be between 30 and 600 seconds.")
    if not 60 <= args.wall_timeout_seconds <= 3600:
        parser.error("The total deadline must be between 60 and 3600 seconds.")
    if os.name != "posix":
        parser.error("This wrapper requires a POSIX host for isolated process-group cleanup.")
    flutter = args.flutter or shutil.which("flutter")
    if not flutter and os.environ.get("FLUTTER_ROOT"):
        flutter = str(Path(os.environ["FLUTTER_ROOT"]) / "bin" / "flutter")
    if not flutter or not Path(flutter).is_file():
        parser.error("Provide the existing Flutter executable with --flutter.")

    provider = args.provider or "none"
    command = [
        flutter, "drive", "--no-pub", "--debug", "--keep-app-running", "-d", args.device,
        "--driver=test_driver/integration_test.dart",
        "--target=integration_test/login_native_smoke_test.dart",
        "--dart-define=LOGIN_SMOKE_MODE=" + args.mode,
        "--dart-define=LOGIN_SMOKE_PROVIDER=" + (args.provider or ""),
        "--dart-define=LOGIN_SMOKE_TIMEOUT_SECONDS=" + str(args.timeout_seconds),
    ]
    print("Starting native smoke harness. Raw Flutter/native output is withheld.", flush=True)
    if args.mode == "email-login":
        print("Enter email and password directly on the device, then tap Sign in.", flush=True)
    elif assisted:
        print("Complete or cancel the selected real provider on the device when prompted.", flush=True)
    return run_command(command, args.mode, provider, args.wall_timeout_seconds)


if __name__ == "__main__":
    sys.exit(main())
