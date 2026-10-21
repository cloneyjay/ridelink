import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../push/push_messaging.dart';

/// Starts Firebase when `android/app/google-services.json` was present at build time.
/// Without it (or on any failure) the app runs with push and Crashlytics off.
Future<bool> initFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) debugPrint('firebase: off ($e)');
    return false;
  }
  await _initCrashlytics();
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessage);
  } catch (e) {
    if (kDebugMode) debugPrint('firebase: no background handler ($e)');
  }
  return true;
}

/// Release builds only. No custom keys or user identifiers are set: reports carry no tokens or
/// personal data.
Future<void> _initCrashlytics() async {
  try {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    if (kDebugMode) return;
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    if (kDebugMode) debugPrint('firebase: crashlytics unavailable ($e)');
  }
}
