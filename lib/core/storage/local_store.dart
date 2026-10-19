import 'package:shared_preferences/shared_preferences.dart';

/// Small device-local key-value storage (non-secret state only).
abstract class LocalStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  List<String> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);
  Future<void> remove(String key);
}

class SharedPrefsLocalStore implements LocalStore {
  SharedPrefsLocalStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  List<String> getStringList(String key) =>
      _prefs.getStringList(key) ?? const [];

  @override
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class MemoryLocalStore implements LocalStore {
  final values = <String, Object>{};

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  List<String> getStringList(String key) =>
      (values[key] as List<String>?) ?? const [];

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      values[key] = List.of(value);

  @override
  Future<void> remove(String key) async => values.remove(key);
}
