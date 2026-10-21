import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import 'local_notifier.dart';
import 'push_locale.dart';
import 'push_payload.dart';

/// The FCM token source and foreground message stream.
abstract class PushMessaging {
  /// False when Firebase isn't configured on this build; push is then off.
  bool get available;

  Future<String?> token();

  Stream<String> get onTokenRefresh;

  /// Data of messages that arrive while the app is in the foreground.
  Stream<Map<String, dynamic>> get onForegroundMessage;
}

class DisabledPushMessaging implements PushMessaging {
  const DisabledPushMessaging();

  @override
  bool get available => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => const Stream.empty();
}

class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging([FirebaseMessaging? messaging])
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  bool get available => true;

  // The classic registration token: what the server's FCM HTTP v1 sends target. The FID
  // register()/onRegistered API needs server-side direct-send support first.
  @override
  Future<String?> token() async {
    try {
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('push: no FCM token ($e)');
      return null;
    }
  }

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map((m) => m.data);
}

/// Shows the localized system notification for a background/terminated push.
Future<void> showBackgroundPush(
  Map<String, dynamic> data,
  LocalNotifier notifier,
  AppLocalizations strings,
) async {
  final payload = PushPayload.fromData(data);
  if (payload == null) return;
  await notifier.initialize(strings: strings);
  await notifier.show(localNotificationFor(payload, strings));
}

/// FCM background entry point (its own isolate: no BuildContext, no providers).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessage(RemoteMessage message) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final strings = localizationsFor(
      saved: prefs.getString(localeStoreKey),
      device: PlatformDispatcher.instance.locale,
    );
    await showBackgroundPush(message.data, FlutterLocalNotifier(), strings);
  } catch (e) {
    if (kDebugMode) debugPrint('push: background message failed ($e)');
  }
}
