# Al Khazna - Financial Management App Setup Guide

This guide provides instructions for setting up and running the Al Khazna application on various platforms, with special attention to emulator testing and Google Sign-In functionality.

## Prerequisites

1. Install Flutter SDK: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. Install Android Studio with Android SDK
3. Create an Android Virtual Device (AVD) for testing
4. Set up a Firebase project: [https://console.firebase.google.com/](https://console.firebase.google.com/)

## Getting Started

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd alkhazna
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Setting Up Firebase for Google Sign-In

### 1. Get SHA-1 Fingerprint for Debug Keystore

1. Open a terminal/command prompt
2. Run the following command to get the SHA-1 fingerprint:
   ```
   keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   On macOS/Linux:
   ```
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
3. Copy the SHA-1 fingerprint value

### 2. Configure Firebase Project

1. Go to the Firebase Console (https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Register your Android app with the package name "com.example.alkhazna"
4. When prompted, add the SHA-1 fingerprint you obtained in the previous step
5. Download the google-services.json file and place it in the `android/app` directory
6. Update the strings.xml file with your Firebase configuration values

### 3. Configure Google Sign-In

1. In the Firebase Console, go to Authentication
2. Enable the Google Sign-In provider
3. Configure OAuth consent screen if required

## Setting Up Emulator for Google Sign-In

### 1. Configure Emulator

- When creating your AVD, make sure to select a Google API image (not just the basic Android image)
- Alternatively, you can add Google Play Services to an existing emulator through the AVD manager

### 2. Add Google Account to Emulator

1. Open the emulator's Settings
2. Go to "Accounts" or "Users & accounts"
3. Add a Google account to the emulator

### 3. Testing Google Sign-In

1. Launch the app on the emulator
2. Try to sign in with Google
3. If you encounter issues, check the error messages and follow the troubleshooting steps

## Troubleshooting Common Issues

### Issue: "Google Play Services not found" error
- Solution: Make sure you're using a Google API image for your emulator
- Alternatively, install Google Play Services manually using the method in EMULATOR_SETUP.md

### Issue: "Network error" when trying to sign in
- Solution: Ensure the emulator has internet connectivity
- Check if your firewall is blocking emulator connections

### Issue: "Authentication failed" error
- Solution: Verify that the SHA-1 fingerprint in your Firebase project matches your debug keystore
- Ensure the google-services.json file is in the correct location

### Issue: App crashes when clicking Google Sign-In
- Solution: Check the logs for specific error messages
- Verify that all required dependencies are properly installed

## Building for Production

1. Update the version number in pubspec.yaml
2. Create a release keystore and update the signing configuration
3. Generate release APK/AAB:
   ```bash
   flutter build apk --release
   ```
   or
   ```bash
   flutter build appbundle --release
   ```

## Contributing

1. Fork the repository
2. Create a new branch for your feature
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
