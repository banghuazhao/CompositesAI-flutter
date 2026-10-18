# Native login smoke tests

## Validation on 18 October 2026

- All 388 Flutter tests passed. The unchanged wrapper privacy/lifecycle tests
  previously passed all 11 checks. Analysis passed for the changed Dart files.
- Automated recovery coverage includes profile timeouts and Retry hydration,
  reset-code recipient binding/resend cooldown, and offline logout with late
  account responses and navigation away from the profile screen.
- Name editing coverage includes prefill, validation, failure and retry, bounded
  requests, session isolation and protection against older profile responses.
- Two physical-iPhone UI runs were stopped before app launch after Xcode's asset
  compiler stopped making progress. Neither run produced a passing device result.
  The underlying macOS tooling cause was not established.
- Native login, cancellation, restoration and logout checks remain unverified.
  The follow-up iPhone run was stopped when the user requested skipping device
  checks. Physical Android and Google Play installation checks remain deferred.

Microsoft uses MSAL multiple-account mode for app-scoped cache removal and account
selection. Android managed shared devices require MSAL single-account mode and
are not supported by this Microsoft flow; other login methods remain available.

## Harness

These tests use the real app bootstrap, native sign-in plugins, secure storage and
configured backend. They do not substitute provider responses, create accounts,
send reset emails, change passwords or enter credentials. The production entry
point has no driver extension. The dedicated `integration_test` target supplies
the test-only driver service.

Use the wrapper below. It discards raw Flutter/native output and prints only
fixed progress stages and credential-free result fields. It saves no raw logs,
screenshots, passwords, account identifiers, authorization codes or tokens. Do not
put credentials in source, command arguments, dart-defines or shell history.
Enter them only in the provider's native UI when that provider requires them.

## Setup

Run `flutter pub get` using this project's configured SDK. Choose an iOS or
Android device from `flutter devices`. Physical-device development signing and
the configured provider callback registrations must support the debug test app.
This is separate from store signing. Keep the device unlocked and dismiss any
normal startup permission or review prompts before interacting with sign-in.
The output-filtering wrapper runs on macOS or Linux so it can isolate and clean
up its own child process group.

Run one mode at a time, replacing `DEVICE_ID`:

```sh
python3 scripts/run_native_login_smoke.py --device DEVICE_ID --mode ui
```

If Flutter is not on PATH, add `--flutter /absolute/path/to/flutter/bin/flutter`.
`FLUTTER_ROOT` is also supported. No app configuration values should be passed
through these arguments.

## What each mode proves

| Mode | Starting state | Verified behavior |
| --- | --- | --- |
| `ui` | Signed out | Real app starts; platform-appropriate providers appear; sign-up and reset forms open and close without sending requests. |
| `email-login` | Signed out | Waits for the operator to enter credentials on the device and press Sign in; checks a started attempt, signed-in navigation and a persisted backend session. |
| `oauth-cancel --provider PROVIDER` | Signed out | Starts the real provider; waits for the operator to cancel; checks a silent return to login and no saved app session. |
| `oauth-login --provider PROVIDER` | Signed out | Starts the real provider; waits for the operator to finish; checks navigation to signed-in chat and a persisted backend session. |
| `restore` | Previously signed in | A separate invocation loads the saved session and verifies it with the backend. The operator must separately confirm the app process was force-closed. |
| `logout` | Signed in | Uses Account & Settings → Profile → Sign Out; checks the saved session and private chat/attachment state are cleared. |

`PROVIDER` is `google`, `github`, `microsoft`, or `apple`. Apple is available only
on iOS. LinkedIn is not currently exposed in the app and is outside this matrix.
Email/password login must be entered manually in the real app; this harness does
not transport account credentials. Start `--mode email-login` without a provider
argument. Its progress stage is `awaiting_email_login` and its result scope is
`assisted_email_auth`. Enter credentials only on the device, then press Sign in.

Assisted modes wait up to four minutes by default. Use
`--timeout-seconds 600` if a provider needs more time. The operator completes
native account selection, consent, browser authorization, device verification or
biometrics on the device. Cancelling GitHub means return to the app and tap
Cancel in its authorization dialog. A configuration error is a failed test, not
a cancellation pass.

An OAuth cancellation pass also requires observing the view model start a real
attempt before returning to idle. An unchanged login screen after a no-op tap
cannot pass. This records app-side attempt behavior; the operator must still
confirm the native prompt was actually shown.

The wrapper has a separate **20-minute total deadline**, covering build,
installation, driver connection and test execution. Change it with
`--wall-timeout-seconds` (60–3600). Timeout or interruption stops only the child
process group created by that invocation; it does not stop unrelated Flutter
tasks. Fixed build progress/failure categories may be shown, but raw diagnostics,
paths and native error strings remain withheld. A category is advisory; a
nonzero Flutter exit always fails the run.

The wrapper's privacy, result-evidence checks and process cleanup can be tested
without launching Flutter:

```sh
python3 -m unittest discover -s scripts -p 'test_native_login_smoke.py'
```

## Per-provider sequence

For each provider visible on that platform:

1. Start signed out; run `oauth-cancel` and cancel the real prompt.
2. Run `oauth-login`; complete sign-in with an authorized test account.
3. Force-close the app process on the device. Run `restore` in a new invocation.
   Record the force-close separately; the test itself cannot prove an OS restart.
4. Run `logout`.
5. Run `oauth-login` again. For Microsoft, confirm account selection is shown
   and a different authorized account can be selected when available.
6. Finish with `logout` if the next provider needs a signed-out start.

For email/password, use `email-login`, force-close/`restore`, `logout`, then
`email-login` again. No account information is passed through the harness.

The harness does not sign out automatically at startup or after a successful
login. A missing starting condition fails the selected mode instead of resetting
the operator's account. Check each result's `mode`, `scope` and completed checks;
an `ui` pass does not establish OAuth success.

Normal launches pass `--keep-app-running`. In this Flutter SDK, the default
`flutter drive` cleanup stops **and uninstalls** an app that it launched. Keeping
it running preserves the installed test app and its local data for the separate
restore, logout and relogin steps. Force-close it manually when checking startup
restoration; hot restart does not establish a cold OS-process restart.

## Store-installed and physical-device evidence

`flutter drive` installs a **debug test build**. Its result always records
`build_source=flutter_drive_debug`, `native_ui_automated=false`,
`play_signed_verified=false`, and `cold_restart_verified=false`.

For a Google Play production check, install the app from Google Play on a physical
Android device and perform the sequence manually. Do not replace that install
with the debug harness and call it a Play-signed test. This specifically matters
for Microsoft and Google signing-certificate callback configuration. The Play
binary has no integration-test driver.

Record results without account details:

| Platform / build origin | Provider | Native prompt observed | Cancel | Success | Force-close / restore | Logout / relogin | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Physical iPhone / debug test | Google, GitHub, Microsoft, Apple, email | Pending | Pending | Pending | Pending | Pending | Not run |
| Physical Android / Play install | Google, GitHub, Microsoft, email | Pending | Pending | Pending | Pending | Pending | Not run |

Use one row per provider when executing. Leave unavailable hardware, missing
accounts or registration failures marked blocked/unverified. A simulator pass
does not replace physical-device or Play-installed evidence. No login flow has
been run merely by adding this harness.
