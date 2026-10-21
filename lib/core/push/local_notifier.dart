import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../l10n/app_localizations.dart';
import 'push_payload.dart';
import 'push_text.dart';

/// A system notification built from a push.
class LocalPushNotification {
  const LocalPushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.channel,
    required this.channelName,
    required this.channelDescription,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final PushChannel channel;
  final String channelName;
  final String channelDescription;
  final String payload;
}

LocalPushNotification localNotificationFor(PushPayload p, AppLocalizations l) {
  final text = pushText(p, l);
  final channel = pushChannelFor(p);
  return LocalPushNotification(
    id: p.notificationTag,
    title: text.title,
    body: text.body,
    channel: channel,
    channelName: channel.name(l),
    channelDescription: channel.description(l),
    payload: p.encode(),
  );
}

abstract class LocalNotifier {
  /// [onTap] receives the payload of a notification tapped while the app is running.
  Future<void> initialize({
    required AppLocalizations strings,
    void Function(String? payload)? onTap,
  });

  /// The payload of the notification that launched the app, if any.
  Future<String?> launchPayload();

  Future<void> show(LocalPushNotification n);
}

class FlutterLocalNotifier implements LocalNotifier {
  FlutterLocalNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _icon = 'ic_stat_ridelink';
  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize({
    required AppLocalizations strings,
    void Function(String? payload)? onTap,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
      onDidReceiveNotificationResponse: (r) => onTap?.call(r.payload),
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final channel in PushChannel.values) {
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          channel.id,
          channel.name(strings),
          description: channel.description(strings),
          importance: _importance(channel),
        ),
      );
    }
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  @override
  Future<void> show(LocalPushNotification n) => _plugin.show(
    id: n.id,
    title: n.title,
    body: n.body,
    payload: n.payload,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        n.channel.id,
        n.channelName,
        channelDescription: n.channelDescription,
        icon: _icon,
        importance: _importance(n.channel),
        priority: n.channel == PushChannel.offers
            ? Priority.high
            : Priority.defaultPriority,
      ),
    ),
  );

  static Importance _importance(PushChannel c) =>
      c == PushChannel.offers ? Importance.high : Importance.defaultImportance;
}
