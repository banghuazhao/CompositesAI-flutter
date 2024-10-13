# SwiftComp-flutter
[![Version](https://img.shields.io/github/v/release/banghuazhao/swiftcomp-flutter)](https://github.com/banghuazhao/swiftcomp-flutter/releases)
[![License](https://img.shields.io/github/license/banghuazhao/EasyToast)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20|%20android-blue)](#)
[![App Store](https://img.shields.io/badge/App%20Store-Download-blue.svg)](https://apps.apple.com/us/app/swiftcomp-composite-calculator/id1297825946)
[![Google Play](https://img.shields.io/badge/Google%20Play-Download-green.svg)](https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp&hl=en_US)

SwiftComp-flutter is a mobile application designed to provide a comprehensive composite calculator based on the SwiftComp software, an efficient multiscale modeling tool for composites. The app is available on both the App Store and Google Play Store, making it accessible to a wide range of users.

## ✨ Features

- **Lamina Stress/Strain:** Calculate stress and strain for lamina layers.
- **Lamina Engineering Constants:** Determine the engineering constants for individual lamina.
- **Laminar Stress/Strain:** Analyze stress and strain across multiple lamina layers.
- **Laminate Plate Properties:** Compute the properties of laminate plates.
- **Laminate 3D Properties:** Evaluate the three-dimensional properties of laminate materials.
- **UDFRC Properties:** Calculate the properties for user-defined fiber-reinforced composites (UDFRC).
- **Chat (Coming Soon):** A built-in AI expert chat feature is currently under development.

## 📋 Requirements

- Dart: >=3.3.0 <4.0.0
- Flutter: >=3.19.0

## 📲 Installation Guide

### Prerequisites
Make sure you have Flutter installed on your system. You can follow the official Flutter [installation guide](https://flutter.dev/docs/get-started/install) if you haven’t done so already.
Please install Flutter `3.19.0`

1. **Clone the Repository**
```bash
git clone https://github.com/banghuazhaoswiftcomp-flutter.git
cd swiftcomp-flutter
```

2. **Install Dependencies** Install the necessary Flutter dependencies by running:
```bash
flutter pub get
```

3. **Set Up Environment Variables** Create a `.env` file in the root directory and add the necessary environment variables. For example:
```
OPENAI_API_KEY=your_openai_api_key
AMPLIFY_CONFIG=your_amplify_config_json
```

4. **Run the Application** 
```bash
flutter run
```
Then choose your device, it could be iOS, Android, or web.


## ⬇️ Download

### iOS
Download SwiftComp from the [App Store](https://apps.apple.com/us/app/swiftcomp-composite-calculator/id1297825946).

### Android
Download SwiftComp from the [Google Play Store](https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp&hl=en_US).

## 🖼️ Screenshots

<p align="center">
<img src="./sreenshots/sc1.webp" alt="iOS Screenshot" width="200">
<img src="./sreenshots/sc2.webp" alt="iOS Screenshot" width="200">
<img src="./sreenshots/sc3.webp" alt="iOS Screenshot" width="200">
</p>


## 🚀 Usage

1. **Select a Material:** Choose from the existing material database or add a new material.
2. **Input Parameters:** Enter the necessary parameters for your composite material.
3. **Calculate:** Press the calculate button to obtain results.
4. **View Results:** The app provides detailed information on the composite's properties.
5. **Chat:** A built-in AI expert chat feature is currently under development.

## 🤝 Contributing
Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a pull request.

## 📄 License
SwiftComp-flutter is released under the MIT License. See [LICENSE](LICENSE) for details.
