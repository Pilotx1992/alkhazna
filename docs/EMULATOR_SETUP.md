# Al Khazna Emulator Setup Guide

This guide provides instructions for setting up the Al Khazna app on an emulator, particularly for Google Sign-In functionality.

## Prerequisites

1. Install Android Studio and the Android SDK
2. Create an Android Virtual Device (AVD) for testing
3. Set up a Firebase project (https://console.firebase.google.com/)

## Setting Up Google Sign-In on Emulator

### 1. Configure Emulator for Google Services

- When creating your AVD, make sure to select a Google API image (not just the basic Android image)
- Alternatively, you can add Google Play Services to an existing emulator through the AVD manager

### 2. Get SHA-1 Fingerprint for Debug Keystore

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

### 3. Configure Firebase Project

1. Go to the Firebase Console (https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Register your Android app with the package name "com.example.alkhazna"
4. When prompted, add the SHA-1 fingerprint you obtained in the previous step
5. Download the google-services.json file and place it in the `android/app` directory

### 4. Update Strings.xml

1. Open `android/app/src/main/res/values/strings.xml`
2. Replace "YOUR_GOOGLE_APP_ID" with your actual Google App ID from Firebase

### 5. Configure Google Sign-In

1. In the Firebase Console, go to Authentication
2. Enable the Google Sign-In provider
3. Configure OAuth consent screen if required

## Testing Google Sign-In on Emulator

### Method 1: Using Google Account on Emulator

1. Open the emulator's Settings
2. Go to "Accounts" or "Users & accounts"
3. Add a Google account to the emulator
4. Launch the app and try to sign in with Google

### Method 2: Using Custom Google Play Services

If you encounter issues with the emulator's Google Play Services:

1. Download the Google Play Services APK from a trusted source
2. Install it on the emulator using:
   ```
   adb path/to/google_play_services.apk
   ```
3. Restart the emulator

## Common Issues and Solutions

### Issue: "Google Play Services not found" error
- Solution: Make sure you're using a Google API image for your emulator
- Alternatively, install Google Play Services manually using the method above

### Issue: "Network error" when trying to sign in
- Solution: Ensure the emulator has internet connectivity
- Check if your firewall is blocking emulator connections

### Issue: "Authentication failed" error
- Solution: Verify that the SHA-1 fingerprint in your Firebase project matches your debug keystore
- Ensure the google-services.json file is in the correct location

### Issue: App crashes when clicking Google Sign-In
- Solution: Check the logs for specific error messages
- Verify that all required dependencies are properly installed

## Additional Tips

- For development, consider using a real device whenever possible, as emulators can have limitations with Google services
- If you're using a physical device, make sure it has Google Play Services installed
- Keep your emulator and development tools up to date to avoid compatibility issues

## References

- [Firebase Android Setup Guide](https://firebase.google.com/docs/android/setup)
- [Google Sign-In for Android](https://developers.google.com/identity/sign-in/android/start-integrating)
- [Android Emulator with Google Services](https://developer.android.com/studio/run/emulator-google)
