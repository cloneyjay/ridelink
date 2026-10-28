# ridelink

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on every pull request, every push to `main`,
and on demand (Actions tab, "Run workflow").

- **Analyze and test** (all runs): `flutter pub get`, a check that the generated localizations in
  `lib/l10n` match the `.arb` files (run `flutter gen-l10n` and commit if it fails),
  `flutter analyze`, `flutter test`.
- **Build debug APK** (pushes to `main` and manual runs, after the checks pass):
  `flutter build apk --debug` with the default `AppConfig` settings (server at
  `http://10.0.2.2:8080`, the Android emulator's address for the host machine; Google sign-in
  hidden).

To download the APK: open the run in the repository's Actions tab and download the
`ridelink-debug-apk-<short sha>` artifact under "Artifacts". Artifacts are kept for 14 days.

CI builds debug APKs only. Release signing and store builds come after the final package name is
chosen, since the release keystore is tied to it.

## Firebase (push notifications and crash reports)

The app builds and runs without Firebase: push notifications and Crashlytics stay off until
Firebase is configured.

To turn them on (after the final package name is chosen):

1. Create the Firebase project and add an Android app with the app's package name.
2. Download `google-services.json` and put it at `android/app/google-services.json`.
3. Rebuild. The Google services and Crashlytics Gradle plugins are applied automatically when
   that file exists (`android/app/build.gradle.kts`).

Crash reports are sent from release builds only.
