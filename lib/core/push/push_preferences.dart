import 'dart:ui';

import '../storage/local_store.dart';
import 'push_locale.dart';

/// Device preferences for notifications: the app language (read by the background isolate)
/// and whether the permission prompt was already shown on this install.
class PushPreferences {
  PushPreferences(this._store);

  static const notificationsAskedKey = 'ridelink.notifications_asked';

  final LocalStore _store;

  /// True while the prompt flow is running (one system prompt at a time).
  bool asking = false;

  Future<void> saveLocale(Locale locale) => saveAppLocale(_store, locale);

  bool get notificationsAsked =>
      _store.getString(notificationsAskedKey) != null;

  Future<void> markNotificationsAsked() =>
      _store.setString(notificationsAskedKey, '1');
}
