# CompositesAI (Former SwiftComp)

[![Version](https://img.shields.io/github/v/release/banghuazhao/swiftcomp-flutter)](https://github.com/banghuazhao/swiftcomp-flutter/releases)
[![License](https://img.shields.io/github/license/banghuazhao/swiftcomp-flutter)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20Web-blue)](#)
[![App Store](https://img.shields.io/badge/App%20Store-Download-blue.svg)](https://apps.apple.com/us/app/swiftcomp-composite-calculator/id1297825946)
[![Google Play](https://img.shields.io/badge/Google%20Play-Download-green.svg)](https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp&hl=en_US)

CompositesAI is a cross-platform Flutter app for composite materials engineering. It combines SwiftComp-based composite calculators with an AI chat assistant for questions, calculations, and simulation-oriented workflows.

The app is available for iOS, Android, and the web at [compositesai.com](https://compositesai.com/).

## Features

- AI chat assistant for composites questions, calculations, and guided workflows.
- Lamina stress/strain calculator for a single layer with arbitrary fiber orientation.
- Lamina engineering constants calculator.
- Laminate stress/strain calculator.
- Laminate plate properties calculator, including ABD matrices.
- Laminate 3D properties calculator.
- UDFRC rules-of-mixtures calculator for unidirectional fiber-reinforced composites.
- Account flows for sign in, sign up, password reset, profile settings, and provider sign-in.
- Localized UI for English, Simplified Chinese, and Traditional Chinese.

## Screenshots

<p align="center">
  <img src="./sreenshots/1.png" alt="SwiftComp screenshot 1" width="200">
  <img src="./sreenshots/2.png" alt="SwiftComp screenshot 2" width="200">
  <img src="./sreenshots/3.png" alt="SwiftComp screenshot 3" width="200">
</p>

## Tech Stack

- Flutter and Dart
- Provider for app state
- GetIt for dependency injection
- Local packages for domain, data, infrastructure, and shared UI components
- `composite_calculator` for composite mechanics calculations
- Fastlane metadata and lanes for mobile release workflows

## Requirements

- Flutter stable. CI currently uses Flutter `3.41.7`.
- Dart `>=3.3.0 <4.0.0`.
- Xcode and CocoaPods for iOS builds.
- Android Studio or Android SDK tooling for Android builds.

The repository includes an `.fvmrc` that tracks the Flutter stable channel. If you use FVM:

```bash
fvm install
fvm flutter pub get
```

## Project Structure

```text
lib/
  app/                  App shell and dependency injection
  generated/            Generated localization files
  l10n/                 ARB localization sources
  presentation/         Chat, tools, auth, and settings UI
  util/                 Shared app utilities
packages/
  domain/               Use cases, entities, and repository contracts
  data/                 Repository implementations and API-facing data logic
  infrastructure/       Auth, HTTP, token, feature flag, and platform services
  ui_components/        Shared reusable UI widgets
test/                   App-level widget and view model tests
integration_test/       Integration test entry point
android/                Android app and Fastlane config
ios/                    iOS app and Fastlane config
```

## Getting Started

1. Clone the repository:

```bash
git clone https://github.com/banghuazhao/swiftcomp-flutter.git
cd swiftcomp-flutter
```

2. Create local configuration files as needed. At minimum, local development and CI expect a `.env` file to exist:

```bash
touch .env
```

The app also declares `msal_config.json` as an asset for Microsoft authentication. Keep environment-specific credentials out of commits.

3. Install dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

Select an iOS simulator, Android emulator/device, or supported web target when prompted.

## Quality Checks

Run the same checks used by CI:

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

## Downloads

- [Download SwiftComp from the App Store](https://apps.apple.com/us/app/swiftcomp-composite-calculator/id1297825946)
- [Download SwiftComp from Google Play](https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp&hl=en_US)
- [Use SwiftComp online](https://compositesai.com/)

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

## License

SwiftComp / CompositesAI is released under the MIT License. See [LICENSE](LICENSE) for details.
