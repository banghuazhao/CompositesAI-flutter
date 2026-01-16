# SwiftComp-flutter
[![Version](https://img.shields.io/github/v/release/banghuazhao/swiftcomp-flutter)](https://github.com/banghuazhao/swiftcomp-flutter/releases)
[![License](https://img.shields.io/github/license/banghuazhao/EasyToast)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20|%20android-blue)](#)
[![App Store](https://img.shields.io/badge/App%20Store-Download-blue.svg)](https://apps.apple.com/us/app/swiftcomp-composite-calculator/id1297825946)
[![Google Play](https://img.shields.io/badge/Google%20Play-Download-green.svg)](https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp&hl=en_US)


SwiftComp-flutter is a mobile app designed to provide a comprehensive composite calculator based on the SwiftComp software, a general-purpose multiscale constitutive modeling code for composites. The app is available on both the App Store, Google Play Store, and [web](https://compositesai.com/), making it accessible to a wide range of users.


## ✨ Features

- **Lamina Stress/Strain:** Compute stress and strain for a single layer with arbitrary fiber orientation.
- **Lamina Engineering Constants:** Compute engineering constants for a lamina with arbitrary fiber orientation.
- **Laminar Stress/Strain:** Compute stress and strain distribution within a lamiante.
- **Laminate Plate Properties:** Compute the ABD matrices for a laminate.
- **Laminate 3D Properties:** Compute 3D properties for a laminate.
- **UDFRC Properties:** Compute 3D properties for unidirectional fiber-reinforced composites (UDFRC).
- **Chat:** A built-in AI Campanion for asking questions and performing calculations.


## 🖼️ Screenshots

<p align="center">
<img src="./sreenshots/1.png" alt="iOS Screenshot" width="200">
<img src="./sreenshots/2.png" alt="iOS Screenshot" width="200">
<img src="./sreenshots/3.png" alt="iOS Screenshot" width="200">
</p>

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
```

4. **Run the Application** 
```bash
flutter run
```
Then choose your device, it could be iOS, Android, or web.


## ⬇️ Download to Mobile

### iOS
[Download SwiftComp from the App Store](https://apps.apple.com/us/app/swiftcomp-composite-calculator/id1297825946).

### Android
[Download SwiftComp from the Google Play Store](https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp&hl=en_US).

## 🌐 Web Access
[Use SwiftComp online](https://compositesai.com/)


## 🚀 Usage

1. **Select a Tool:** From the Tools tab, choose the desired composite calculator.
2. **Input Parameters:** Enter the required parameters for your composite material. Note that inputs vary by tool.
3. **Calculate:** Press the calculate button to obtain results.
4. **View Results:** Once calculation is complete, the results page will be displayed.
5. **Chat:** Ask any questions related to composites, composites simulation, invoke simulations using natural language.


## 🤝 Contributing
Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a pull request.

## 📄 License
SwiftComp-flutter is released under the MIT License. See [LICENSE](LICENSE) for details.
