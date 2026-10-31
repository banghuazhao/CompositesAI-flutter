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

Create the release archive from the production entry point. The Release
configuration defaults to Automatic signing with a development identity, which
embeds `get-task-allow`. Select the Mac App Store distribution profile and
identity for the archive with command-line overrides (or the ignored
`Secrets.xcconfig`):

```sh
FLUTTER_MACOS_ARM64_ONLY=false flutter build macos --release --config-only --target=lib/main.dart
FLUTTER_MACOS_ARM64_ONLY=false xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination 'generic/platform=macOS' \
  -archivePath build/macos/archive/CompositesAI.xcarchive \
  COMPOSITESAI_CODE_SIGN_STYLE=Manual \
  COMPOSITESAI_PROVISIONING_PROFILE='<MAC_APP_STORE_PROFILE_NAME>' \
  CODE_SIGN_IDENTITY='3rd Party Mac Developer Application' \
  archive
```

The legacy Catalyst profile authorizes the existing prefixed Mac bundle ID, but
it also carries the iOS-style `get-task-allow` and `application-identifier`
keys. Xcode copies them into the native macOS runner's signature, and App Store
Connect rejects them (error 90285). The macOS equivalents
(`com.apple.application-identifier` and `com.apple.developer.team-identifier`)
are already present, so re-sign a copy of the app without the two iOS-only keys:

```sh
mkdir -p build/macos/store
rm -rf build/macos/store/CompositesAI.app
ditto build/macos/archive/CompositesAI.xcarchive/Products/Applications/CompositesAI.app \
  build/macos/store/CompositesAI.app
codesign -d --entitlements - --xml build/macos/store/CompositesAI.app > build/macos/store/ent.plist
plutil -remove get-task-allow build/macos/store/ent.plist
plutil -remove application-identifier build/macos/store/ent.plist
codesign -f -s '<MAC_APP_DISTRIBUTION_IDENTITY>' --entitlements build/macos/store/ent.plist \
  --generate-entitlement-der build/macos/store/CompositesAI.app
codesign --verify --deep --strict build/macos/store/CompositesAI.app
```

Xcode's export workflow can reject the profile's classification for the native
macOS runner, so package the re-signed app with Apple's `productbuild` workflow
and the installed Mac Installer Distribution identity:

```sh
productbuild --sign '<MAC_INSTALLER_DISTRIBUTION_IDENTITY>' \
  --component build/macos/store/CompositesAI.app \
  /Applications build/macos/store/CompositesAI.pkg
```

Validate, then upload, with an App Store Connect API key whose `.p8` file is in
`API_PRIVATE_KEYS_DIR`:

```sh
xcrun altool --validate-app -f build/macos/store/CompositesAI.pkg -t macos \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID> --output-format json
xcrun altool --upload-app -f build/macos/store/CompositesAI.pkg -t macos \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID> --output-format json
```

`altool` exits with status 0 even when validation fails, so read the JSON for
`product-errors` or the `success-message`. Keep the signing identity and API key
values out of logs and shell history. Leave the existing bundle ID and profile
contents intact. The Mac app is a separate App Store Connect record
("CompositesAI for Mac"); 7.14.0 was the first native build submitted this way.

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
