# user_app

A new Flutter project.

## Android: Google Play Services crash (ApiException / onConnectionFailed)

If the app crashes on Android with a stack trace like `ApiExceptionUtil.fromStatus`, `onConnectionFailed`, or "Lost connection to device" from `com.google.android.gms`, the failure is usually due to Google Play Services not being available or APIs not being enabled.

**Do this:**

1. **Emulator**  
   Use an AVD image that includes **Google Play** (not only "Google APIs"). In AVD Manager, pick a system image that shows "Google Play" (e.g. "Pixel 6 API 34" with Play Store). Then update Google Play and Google Play Services in the emulator if prompted.

2. **Real device**  
   Ensure Google Play Services is up to date (Play Store → My apps → update).

3. **APIs**  
   In [Google Cloud Console](https://console.cloud.google.com/) for the project used by this app:
   - Enable **Firebase** (and any Firebase APIs you use).
   - If you use the map screen, enable **Maps SDK for Android** and ensure the API key in `android/app/src/main/res/values/strings.xml` is allowed for that API and (if restricted) for your app’s package name.

4. **Firebase config**  
   Ensure `android/app/google-services.json` matches this app (package name `com.company.kinetic`). Regenerate it from Firebase Console if you changed the app ID.

The app is set up to continue without Firebase if initialization fails in Dart (e.g. no crash and no push notifications). If the process still exits, the failure is in native Play Services code; fixing the environment (steps above) is required.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
