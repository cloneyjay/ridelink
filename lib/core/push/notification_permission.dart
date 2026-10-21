import 'package:permission_handler/permission_handler.dart';

enum NotificationPermissionStatus {
  granted,

  /// Not granted, but the system prompt can still be shown (never asked, or denied once).
  canAsk,

  /// Only the system settings can change it.
  permanentlyDenied,
}

/// POST_NOTIFICATIONS (Android 13+); older Android reports granted.
abstract class NotificationPermission {
  Future<NotificationPermissionStatus> status();
  Future<NotificationPermissionStatus> request();
  Future<void> openSettings();
}

class PlatformNotificationPermission implements NotificationPermission {
  @override
  Future<NotificationPermissionStatus> status() async {
    try {
      return _map(await Permission.notification.status);
    } catch (_) {
      return NotificationPermissionStatus.granted;
    }
  }

  @override
  Future<NotificationPermissionStatus> request() async {
    try {
      return _map(await Permission.notification.request());
    } catch (_) {
      return NotificationPermissionStatus.canAsk;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (_) {}
  }

  static NotificationPermissionStatus _map(PermissionStatus s) => switch (s) {
    PermissionStatus.granted ||
    PermissionStatus.limited ||
    PermissionStatus.provisional => NotificationPermissionStatus.granted,
    PermissionStatus.permanentlyDenied || PermissionStatus.restricted =>
      NotificationPermissionStatus.permanentlyDenied,
    PermissionStatus.denied => NotificationPermissionStatus.canAsk,
  };
}
