# CompositesAI for Mac

The Flutter desktop app requires **macOS 12 or later**. It retains the existing
Mac App Store bundle identifier, `maccatalyst.com.cdmHUB.SwiftComp`, so this is an
update to the existing Mac app rather than a separate product.

## Local signing configuration

Open `macos/Runner.xcworkspace` when working in Xcode. Keep machine-specific
settings in `macos/Runner/Configs/Secrets.xcconfig`, which is ignored by Git and
optionally included by `AppInfo.xcconfig`. A manual-signing configuration uses:

```xcconfig
COMPOSITESAI_TEAM_ID = <APPLE_TEAM_ID>
COMPOSITESAI_CODE_SIGN_STYLE = Manual
COMPOSITESAI_PROVISIONING_PROFILE = <MAC_PROFILE_UUID_OR_NAME>
CODE_SIGN_IDENTITY = <SIGNING_IDENTITY>
```

Use the development identity/profile for local debug tests and the appropriate
Mac App Store distribution identity/profile for a distribution build. Generate
the existing Catalyst app's profiles against the base App ID
`com.cdmHUB.SwiftComp`; keep the runner's bundle identifier as
`maccatalyst.com.cdmHUB.SwiftComp`. Keep certificates, profiles and actual local
signing values outside the repository.

## Build and native smoke test

Run from the repository root with Flutter and Xcode configured:

```sh
flutter pub get
FLUTTER_MACOS_ARM64_ONLY=false flutter build macos --release
FLUTTER_MACOS_ARM64_ONLY=false flutter test integration_test/macos_release_smoke_test.dart -d macos
```

Use the regular Flutter build with `FLUTTER_MACOS_ARM64_ONLY=false` so the build
is not restricted to the current Apple Silicon host. The smoke target launches
the real app and checks guest navigation, responsive layouts, keyboard traversal,
SI/US calculations, native clipboard results and settings. Start with a
signed-out test app profile.

The optional QA flow signs in and edits an **unsent** draft, then signs out. It
runs only when a sandbox-readable local JSON file is supplied:

```sh
FLUTTER_MACOS_ARM64_ONLY=false flutter test integration_test/macos_release_smoke_test.dart -d macos \
  --dart-define=COMPOSITESAI_REVIEWER_CREDENTIALS_PATH=<SANDBOX_READABLE_QA_JSON_PATH>
```

The file contains `email` and `password` string fields. Keep it outside the
repository with owner-only permissions; never put their values in command-line
arguments, screenshots or logs. Omitting the define skips only the QA flow. The
guest smoke still runs. This target does not send AI messages or delete history.
If the file is outside the app's sandbox, select that same file in the native
file picker when prompted; the test uses normal user-selected file access.

For automated QA, build the test app without credentials first:

```sh
flutter build macos --debug --target=integration_test/macos_release_smoke_test.dart \
  --dart-define=COMPOSITESAI_REVIEWER_QA=true
flutter drive -d macos --use-application-binary=build/macos/Build/Products/Debug/CompositesAI.app \
  --driver=integration_test/macos_smoke_driver.dart \
  --target=integration_test/macos_release_smoke_test.dart
```

Have a local secret manager provide `COMPOSITESAI_QA_EMAIL` and
`COMPOSITESAI_QA_PASSWORD` only to the second command's process. Keep them out of
the build environment, Dart defines, app assets, shell history and logs. The test
checks that storage is signed out before using the review account.

Restore the production entry point before creating a release archive:

```sh
FLUTTER_MACOS_ARM64_ONLY=false flutter build macos --release --target=lib/main.dart
```

## Mac App Store package

Create the release archive from the production entry point, with the local
App Store signing configuration selected:

```sh
FLUTTER_MACOS_ARM64_ONLY=false flutter build macos --release --config-only --target=lib/main.dart
FLUTTER_MACOS_ARM64_ONLY=false xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination 'generic/platform=macOS' \
  -archivePath build/macos/archive/CompositesAI.xcarchive archive
```

The legacy Catalyst profile authorizes the existing prefixed Mac bundle ID.
Xcode's export workflow can reject that profile's classification for the native
macOS runner. Package the signed archive using Apple's `productbuild` workflow
instead, with the installed Mac Installer Distribution identity selected by
local secure tooling:

```sh
productbuild --sign '<MAC_INSTALLER_DISTRIBUTION_IDENTITY>' \
  --component build/macos/archive/CompositesAI.xcarchive/Products/Applications/CompositesAI.app \
  /Applications build/macos/store/CompositesAI.pkg
```

Create the output directory first. Keep the signing identity and API key values
out of logs and shell history. Verify the app and installer signatures and use
App Store Connect package validation before uploading. The 7.13.0 package was
rejected by both validation and upload: their JSON responses reported
`get-task-allow` and `application-identifier` entitlement errors despite process
exit status 0. The Mac release remains stopped. Leave the existing bundle ID and
profile contents intact.

## Desktop authentication

Email/password sign-in uses the existing service. Google sign-in is available on
Mac only when `GOOGLE_SIGNIN_CLIENT_ID_MACOS` is configured for the Mac app.
Microsoft sign-in stays gated until `MICROSOFT_MACOS_AUTH_ENABLED=true` is set
with a working Mac registration. Configure these through the existing local
configuration workflow; do not commit credentials or substitute mobile OAuth
registrations for desktop registrations.

## Legacy SwiftComp data

The older Mac app stored materials and named layups in a Core Data SQLite store.
When that store is detected, **Account & Settings → Legacy SwiftComp data →
Export legacy data** saves a separate SQLite backup through the native save
panel. The exporter opens the source read-only and preserves its original
records, values and unit conventions; it does not convert them into the new
material-library schema or overwrite the original store. The new library's JSON
export is a separate backup format.

Store listing sources for the six Mac locales are in `macos/fastlane/metadata/`.
