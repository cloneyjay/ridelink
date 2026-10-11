import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import 'access_token_source.dart';
import 'auth_api.dart';
import 'session.dart';
import 'token_storage.dart';

/// Owns the session: access token in memory, refresh token in secure storage.
class SessionManager extends ChangeNotifier implements AccessTokenSource {
  SessionManager({required this._storage, required this._authApi});

  final TokenStorage _storage;
  final AuthApi _authApi;

  SessionState _state = const SessionUnknown();
  Future<bool>? _inflightRefresh;
  Future<void>? _inflightRestore;

  SessionState get state => _state;

  @override
  String? get accessToken => switch (_state) {
    SignedIn(:final session) => session.accessToken,
    _ => null,
  };

  @override
  bool get hasSession => _state is SignedIn;

  /// Called at startup: restores a stored session, signs out, or goes offline.
  Future<void> restore() => _inflightRestore ??= _restore();

  /// Retries a restore that ended offline.
  Future<void> retry() {
    if (_state is! SessionOffline) return Future.value();
    _inflightRestore = null;
    return restore();
  }

  Future<void> _restore() async {
    final stored = await _storage.readRefreshToken();
    if (stored == null) {
      _set(const SignedOut());
      return;
    }
    try {
      await _apply(await _authApi.refresh(stored));
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        _set(const SessionOffline());
        return;
      }
      await _storage.clear();
      _set(const SignedOut());
    }
  }

  /// Stores a session returned by any sign-in endpoint.
  Future<void> setSession(Session session) => _apply(session);

  @override
  Future<bool> refresh() => _inflightRefresh ??= _refresh().whenComplete(
    () => _inflightRefresh = null,
  );

  Future<bool> _refresh() async {
    final current = _state;
    final token = current is SignedIn
        ? current.session.refreshToken
        : await _storage.readRefreshToken();
    if (token == null) {
      await _signOutLocally();
      return false;
    }
    try {
      await _apply(await _authApi.refresh(token));
      return true;
    } on ApiException catch (e) {
      if (!e.isNetworkError) await _signOutLocally();
      return false;
    }
  }

  Future<void> signOut() async {
    final token = accessToken;
    if (token != null) {
      try {
        await _authApi.logout(token);
      } on ApiException {
        // Best effort: the local session is cleared regardless.
      }
    }
    await _signOutLocally();
  }

  Future<void> _apply(Session session) async {
    await _storage.writeRefreshToken(session.refreshToken);
    _set(SignedIn(session));
  }

  Future<void> _signOutLocally() async {
    await _storage.clear();
    _set(const SignedOut());
  }

  void _set(SessionState next) {
    _state = next;
    notifyListeners();
  }
}
