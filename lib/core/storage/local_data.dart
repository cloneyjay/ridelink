import '../../features/ratings/rating_prompt_store.dart';
import '../mode/app_mode.dart';
import '../push/push_preferences.dart';
import 'local_store.dart';

/// Everything this device remembers about the signed-in user, in one place. Only the device
/// language (a device setting, not user data) survives [clearUserData].
class LocalData {
  LocalData({
    required this._store,
    required this._mode,
    this._resetMemory = const [],
  });

  /// Device-storage keys holding user data; add new user-specific keys here.
  static const userKeys = [
    RatingPromptStore.storageKey,
    PushPreferences.notificationsAskedKey,
  ];

  final LocalStore _store;
  final AppModeController _mode;

  /// In-memory user state (last known location, pending push taps, opened live screens).
  final List<void Function()> _resetMemory;

  /// After the account was deleted, or the server definitively rejected the session. Not on a
  /// normal sign-out. The refresh token is cleared by the session itself.
  Future<void> clearUserData() async {
    for (final key in userKeys) {
      try {
        await _store.remove(key);
      } catch (_) {}
    }
    try {
      await _mode.forget();
    } catch (_) {}
    for (final reset in _resetMemory) {
      reset();
    }
  }
}
