import 'package:flutter/foundation.dart';

/// Set by "Join as a boda boda rider"; after sign-in the router sends the user
/// to rider onboarding instead of home.
class RiderIntent extends ChangeNotifier {
  bool _active = false;

  bool get active => _active;

  void set() {
    if (_active) return;
    _active = true;
    notifyListeners();
  }

  void clear() {
    if (!_active) return;
    _active = false;
    notifyListeners();
  }
}
