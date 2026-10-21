import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/firebase_setup.dart';
import 'core/mode/app_mode.dart';
import 'core/providers.dart';
import 'core/push/local_notifier.dart';
import 'core/push/push_locale.dart';
import 'core/push/push_messaging.dart';
import 'core/push/push_payload.dart';
import 'core/push/push_providers.dart';
import 'core/storage/legacy_keys.dart';
import 'core/storage/local_store.dart';
import 'core/version/version_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are bundled in assets/google_fonts; never download them at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Read before the first frame so the router opens the last-used side directly.
  final prefs = await SharedPreferences.getInstance();
  final localStore = SharedPrefsLocalStore(prefs);
  await removeLegacyKeys(localStore);
  final firebaseReady = await initFirebase();
  final taps = PushTaps();
  await _initLocalNotifications(localStore, taps);
  runApp(
    ProviderScope(
      overrides: [
        modeStoreProvider.overrideWithValue(SharedPrefsModeStore(prefs)),
        localStoreProvider.overrideWithValue(localStore),
        appVersionProvider.overrideWithValue(await _installedVersion()),
        pushTapsProvider.overrideWithValue(taps),
        if (firebaseReady)
          pushMessagingProvider.overrideWithValue(FirebasePushMessaging()),
      ],
      child: const RideLinkApp(),
    ),
  );
}

Future<String> _installedVersion() async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    return '0.0.0';
  }
}

/// Taps on a push notification (app running, or launched by the tap) open the order.
Future<void> _initLocalNotifications(LocalStore store, PushTaps taps) async {
  try {
    final notifier = FlutterLocalNotifier();
    await notifier.initialize(
      strings: localizationsFor(
        saved: store.getString(localeStoreKey),
        device: PlatformDispatcher.instance.locale,
      ),
      onTap: (payload) => taps.add(PushPayload.decode(payload)),
    );
    taps.add(PushPayload.decode(await notifier.launchPayload()));
  } catch (e) {
    if (kDebugMode) debugPrint('push: local notifications unavailable ($e)');
  }
}
