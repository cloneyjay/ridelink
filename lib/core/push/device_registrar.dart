import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import 'push_messaging.dart';

/// POST/DELETE /v1/devices.
abstract class DeviceApi {
  Future<void> register({required String token, required String appVersion});
  Future<void> unregister(String token);
}

class ApiDeviceApi implements DeviceApi {
  ApiDeviceApi(this._api);

  final ApiClient _api;

  @override
  Future<void> register({required String token, required String appVersion}) =>
      _api.post(
        'devices',
        data: {
          'token': token,
          'platform': 'android',
          'app_version': appVersion,
        },
      );

  @override
  Future<void> unregister(String token) =>
      _api.delete('devices', data: {'token': token});
}

/// Keeps this device's FCM token registered for the signed-in user.
class DeviceRegistrar {
  DeviceRegistrar({
    required this._api,
    required this._push,
    required this._appVersion,
  });

  static const unregisterTimeout = Duration(seconds: 5);

  final DeviceApi _api;
  final PushMessaging _push;
  final String _appVersion;

  String? _userId;
  String? _registeredUser;
  String? _registeredToken;
  StreamSubscription<String>? _refreshSub;
  Future<void>? _inflight;

  /// Call on every signed-in state (restore, sign-in, token refresh); repeats are no-ops.
  Future<void> signedIn(String userId) async {
    if (!_push.available) return;
    _userId = userId;
    _refreshSub ??= _push.onTokenRefresh.listen((t) => unawaited(_register(t)));
    if (_registeredUser == userId && _registeredToken != null) return;
    final token = await _push.token();
    if (token != null) await _register(token);
  }

  Future<void> _register(String token) async {
    final user = _userId;
    if (user == null) return;
    if (user == _registeredUser && token == _registeredToken) return;
    while (_inflight != null) {
      await _inflight;
    }
    if (_userId != user ||
        (user == _registeredUser && token == _registeredToken)) {
      return;
    }
    final call = _api.register(token: token, appVersion: _appVersion);
    _inflight = call;
    try {
      await call;
      _registeredUser = user;
      _registeredToken = token;
    } catch (e) {
      // Retried on the next signed-in state change or token refresh.
      if (kDebugMode) debugPrint('push: device registration failed ($e)');
    } finally {
      _inflight = null;
    }
  }

  /// Best effort, before the session is cleared; never delays sign-out for long.
  Future<void> unregister() async {
    if (!_push.available) return;
    try {
      final token = _registeredToken ?? await _push.token();
      if (token != null) {
        await _api.unregister(token).timeout(unregisterTimeout);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('push: device unregistration failed ($e)');
    }
    signedOut();
  }

  void signedOut() {
    _userId = null;
    _registeredUser = null;
    _registeredToken = null;
  }

  Future<void> dispose() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
  }
}
