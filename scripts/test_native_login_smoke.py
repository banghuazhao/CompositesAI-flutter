"""Output privacy and lifecycle regressions; these never launch Flutter."""

import contextlib
import io
import json
import signal
import sys
import time
import unittest
from unittest import mock

import run_native_login_smoke as smoke


def record(mode="ui", provider="none"):
    return {
        "mode": mode,
        "provider": provider,
        "platform": "ios",
        "outcome": "passed",
        "scope": smoke.expected_scope(mode),
        "stage": "complete",
        "completed_checks": sorted(smoke.REQUIRED_CHECKS[mode]),
    }


class NativeLoginRunnerTest(unittest.TestCase):
    def test_normal_drive_keeps_the_app_installed_for_the_next_mode(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output), mock.patch.object(sys, "argv", [
            "smoke", "--device", "test-device", "--flutter", sys.executable,
            "--mode", "restore",
        ]), mock.patch.object(smoke, "run_command", return_value=0) as run:
            self.assertEqual(smoke.main(), 0)
        command = run.call_args[0][0]
        self.assertIn("--keep-app-running", command)
        self.assertNotIn("--no-keep-app-running", command)

    def test_unknown_and_malformed_output_is_discarded(self):
        for value in (
            "opaque native diagnostic",
            "LOGIN_SMOKE_RESULT not-json",
            "LOGIN_SMOKE_PROGRESS []",
            'LOGIN_SMOKE_PROGRESS {"stage": {"unexpected": "shape"}}',
        ):
            with self.subTest(shape=value.split(" ")[0]):
                self.assertIsNone(smoke.safe_record(value, "ui", "none"))

    def test_extra_fields_never_reach_result(self):
        data = record()
        data["opaque_private_field"] = "withheld-value-marker"
        filtered = smoke.safe_record(
            "flutter: LOGIN_SMOKE_RESULT " + json.dumps(data), "ui", "none"
        )
        self.assertIsNotNone(filtered)
        self.assertNotIn("opaque_private_field", filtered)
        self.assertNotIn("withheld-value-marker", json.dumps(filtered))

    def test_nested_or_unknown_completed_checks_are_rejected(self):
        for checks in ([{"unexpected": "shape"}], ["unknown_check"]):
            data = record()
            data["completed_checks"] = checks
            self.assertIsNone(smoke.safe_record(
                "LOGIN_SMOKE_RESULT " + json.dumps(data), "ui", "none"
            ))

    def test_cancellation_requires_a_started_attempt(self):
        data = record("oauth-cancel", "google")
        data["completed_checks"].remove("real_provider_attempt_started")
        self.assertIsNone(smoke.safe_record(
            "LOGIN_SMOKE_RESULT " + json.dumps(data), "oauth-cancel", "google"
        ))

    def test_email_login_requires_its_scope_and_started_attempt(self):
        data = record("email-login")
        line = "LOGIN_SMOKE_RESULT " + json.dumps(data)
        self.assertEqual(smoke.safe_record(line, "email-login", "none")["scope"],
                         "assisted_email_auth")
        data["scope"] = "in_app_ui"
        self.assertIsNone(smoke.safe_record(
            "LOGIN_SMOKE_RESULT " + json.dumps(data), "email-login", "none"
        ))
        data["scope"] = "assisted_email_auth"
        data["completed_checks"].remove("real_email_attempt_started")
        self.assertIsNone(smoke.safe_record(
            "LOGIN_SMOKE_RESULT " + json.dumps(data), "email-login", "none"
        ))

    def test_diagnostics_contain_only_fixed_categories(self):
        self.assertEqual(smoke.classify_tool_line(
            "Running Xcode build... opaque-private-marker"
        ), ("building_ios", None))
        self.assertEqual(smoke.classify_tool_line(
            "No profiles for opaque-private-marker were found"
        ), (None, "signing_configuration"))
        self.assertEqual(smoke.classify_tool_line(
            "opaque-private-marker"
        ), (None, None))

    def test_process_group_cleanup_targets_only_the_created_group(self):
        process = mock.Mock(pid=812345)
        with mock.patch.object(smoke.os, "killpg", side_effect=[
            None, ProcessLookupError()
        ]) as kill_group:
            smoke.stop_process_group(process, first_signal=signal.SIGINT)
        self.assertEqual(kill_group.call_args_list, [
            mock.call(812345, signal.SIGINT), mock.call(812345, 0)
        ])

    def test_tool_start_error_does_not_echo_the_exception(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output), mock.patch.object(
            smoke.subprocess, "Popen", side_effect=OSError("withheld-value-marker")
        ):
            code = smoke.run_command(["unused-tool"], "ui", "none", 1)
        self.assertEqual(code, 1)
        self.assertIn('"failure_category": "tool_start_failed"', output.getvalue())
        self.assertNotIn("withheld-value-marker", output.getvalue())

    def test_raw_output_is_withheld_and_nonzero_exit_never_passes(self):
        data = "LOGIN_SMOKE_RESULT " + json.dumps(record())
        for exit_code in (0, 7):
            output = io.StringIO()
            source = (
                "import sys; print('withheld-value-marker'); "
                "print(" + repr(data) + "); sys.exit(" + str(exit_code) + ")"
            )
            with contextlib.redirect_stdout(output):
                code = smoke.run_command(
                    [sys.executable, "-c", source], "ui", "none", 5
                )
            self.assertEqual(code, 0 if exit_code == 0 else 1)
            self.assertNotIn("withheld-value-marker", output.getvalue())
            if exit_code:
                self.assertNotIn('"outcome": "passed"', output.getvalue())

    def test_wall_deadline_applies_even_after_stdout_closes(self):
        for source in (
            "import time; time.sleep(30)",
            "import os,time; os.close(1); os.close(2); time.sleep(30)",
        ):
            output = io.StringIO()
            started = time.monotonic()
            with contextlib.redirect_stdout(output):
                code = smoke.run_command(
                    [sys.executable, "-c", source], "ui", "none", 0.2
                )
            self.assertEqual(code, 124)
            self.assertLess(time.monotonic() - started, 3)
            self.assertIn('"failure_category": "wall_timeout"', output.getvalue())


if __name__ == "__main__":
    unittest.main()
