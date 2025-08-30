# Google Sign-In Troubleshooting Guide for Emulators

This guide provides solutions to common issues when implementing Google Sign-In on Android emulators.

## Common Issues and Solutions

### 1. "Google Play Services not found" error

**Problem**: When trying to sign in with Google, you get an error message indicating that Google Play Services are not found.

**Solutions**:
1. **Use a Google API image**:
   - Create a new AVD with a Google API system image
   - Avoid using the generic Android system images

2. **Install Google Play Services manually**:
   - Download the Google Play Services APK from a trusted source
   - Install it on the emulator using:
     ```
     adb path/to/google_play_services.apk
     ```
   - Restart the emulator

3. **Update Google Play Services**:
   - Open the emulator's Play Store app
   - Search for "Google Play Services" and update it

### 2. "Network error" or "Connection failed" errors

**Problem**: Google Sign-In fails with network-related errors.

**Solutions**:
1. **Check internet connectivity**:
   - Ensure the emulator has internet access
   - Try opening a web browser in the emulator to verify connectivity

2. **Check firewall settings**:
   - Make sure your firewall isn't blocking emulator connections
   - Try running the app with firewall temporarily disabled

3. **Use a custom DNS**:
   - Some emulators have issues with DNS resolution
   - Try setting a public DNS like 8.8.8.8 in the emulator's network settings

### 3. "Authentication failed" error

**Problem**: Google Sign-In authentication fails with no specific error details.

**Solutions**:
1. **Verify SHA-1 fingerprint**:
   - Ensure the SHA-1 fingerprint in your Firebase project matches your debug keystore
   - Regenerate the SHA-1 if needed and update both Firebase and your app configuration

2. **Check Firebase configuration**:
   - Verify that the google-services.json file is in the correct location (android/app)
   - Ensure the package name in Firebase matches your app's package name (com.example.alkhazna)

3. **Update Firebase project settings**:
   - Make sure Google Sign-In is enabled in the Firebase Console
   - Check that OAuth consent screen is properly configured if required

### 4. App crashes when clicking Google Sign-In

**Problem**: The app crashes immediately when the Google Sign-In button is tapped.

**Solutions**:
1. **Check logs for specific errors**:
   - Run the app with debug logging enabled:
     ```
     flutter run --verbose
     ```
   - Look for stack traces or specific error messages

2. **Verify dependencies**:
   - Ensure all required dependencies are properly installed:
     ```
     flutter pub get
     ```

3. **Clean and rebuild**:
   - Clean the project and rebuild:
     ```
     flutter clean
     flutter pub get
     flutter run
     ```

### 5. "GoogleApiClient is not initialized" error

**Problem**: You get an error related to GoogleApiClient not being initialized.

**Solutions**:
1. **Update Google Play Services**:
   - Ensure the emulator has the latest Google Play Services installed

2. **Check manifest configuration**:
   - Verify that the AndroidManifest.xml has all required Google Play Services metadata and activities

3. **Add missing activities**:
   - Make sure these activities are added to your AndroidManifest.xml:
     ```xml
     <activity android:name="com.google.android.gms.auth.api.signin.internal.SignInHubActivity"
         android:excludeFromRecents="true"
         android:exported="false"
         android:theme="@android:style/Theme.Translucent.NoTitleBar" />
     <activity android:name="com.google.android.gms.common.api.GoogleApiActivity"
         android:exported="false"
         android:theme="@android:style/Theme.Translucent.NoTitleBar" />
     ```

## Advanced Troubleshooting

### Using Android Studio's Logcat

1. Open Android Studio and connect to your emulator
2. Open the Logcat tool (View > Tool Windows > Logcat)
3. Filter logs by your app package name (com.example.alkhazna)
4. Look for errors or warnings related to Google Sign-In or Google Play Services

### Checking Google Play Services version

1. Open the emulator's Settings app
2. Go to "Apps" or "Application Manager"
3. Find "Google Play Services" in the list
4. Check the version and update if necessary

### Resetting Google Sign-In state

1. Go to the emulator's Settings > Accounts
2. Remove any existing Google accounts
3. Restart the emulator
4. Add your Google account again

## Testing on Physical Devices

If you continue to have issues on emulators, consider testing on a physical Android device:

1. Enable Developer Options and USB Debugging on your device
2. Connect the device to your computer via USB
3. Run the app with:
   ```
   flutter run
   ```

Physical devices often have better compatibility with Google services than emulators.

## Getting Help

If you continue to experience issues:

1. Check the [Google Sign-In for Android documentation](https://developers.google.com/identity/sign-in/android/start-integrating)
2. Review the [Firebase Authentication documentation](https://firebase.google.com/docs/auth)
3. Search for similar issues on Stack Overflow or GitHub
4. Create a new issue with detailed logs and steps to reproduce the problem
