import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode {
  sender('sender'),
  rider('rider');

  const AppMode(this.wire);
  final String wire;

  static AppMode? fromWire(String? value) {
    for (final m in values) {
      if (m.wire == value) return m;
    }
    return null;
  }
}

/// Device-local storage for the last-used mode (frontend decision 11).
abstract class ModeStore {
  AppMode? read();
  Future<void> write(AppMode mode);
}

class SharedPrefsModeStore implements ModeStore {
  SharedPrefsModeStore(this._prefs);

  static const _key = 'ridelink.last_mode';
  final SharedPreferences _prefs;

  @override
  AppMode? read() => AppMode.fromWire(_prefs.getString(_key));

  @override
  Future<void> write(AppMode mode) => _prefs.setString(_key, mode.wire);
}

class MemoryModeStore implements ModeStore {
  MemoryModeStore([this.mode]);

  AppMode? mode;

  @override
  AppMode? read() => mode;

  @override
  Future<void> write(AppMode mode) async => this.mode = mode;
}

/// The current mode; persisted on every change so the next launch opens the same side.
class AppModeController extends ChangeNotifier {
  AppModeController(this._store) : _mode = _store.read() ?? AppMode.sender;

  final ModeStore _store;
  AppMode _mode;

  AppMode get mode => _mode;

  void set(AppMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _store.write(mode);
    notifyListeners();
  }
}
