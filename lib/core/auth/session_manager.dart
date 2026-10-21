import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../time/server_clock.dart';
import 'access_token_source.dart';
import 'auth_api.dart';
import 'session.dart';
import 'token_storage.dart';

typedef TimerFactory = Timer Function(Duration delay, void Function() callback);

/// Owns the session: access token in memory, refresh token in secure storage.
///
/// The user stays signed in until they sign out or the server definitively rejects the refresh
/// token; transient refresh failures keep the session and retry with backoff.
class SessionManager extends ChangeNotifier implements AccessTokenSource {
  SessionManager({
    required this._storage,
    required this._authApi,
    ServerClock? clock,
    TimerFactory? timer,
  }) : _clock = clock ?? ServerClock(),
       _startTimer = timer ?? Timer.new;

  /// Access tokens are refreshed this long before they expire.
  static const refreshLeeway = Duration(seconds: 60);

  /// Backoff for retrying a refresh that failed transiently.
  static const minRetryDelay = Duration(seconds: 2);
  static const maxRetryDelay = Duration(minutes: 2);

  final TokenStorage _storage;
  final AuthApi _authApi;
  final ServerClock _clock;
  final TimerFactory _startTimer;

  SessionState _state = const SessionUnknown();
  DateTime? _expiresAt;
  Timer? _timer;
  int _retryAttempt = 0;
  bool _disposed = false;
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

  @override
  bool get accessTokenExpiresSoon {
    final expiresAt = _expiresAt;
    if (_state is! SignedIn || expiresAt == null) return false;
    return !_clock.now().isBefore(expiresAt.subtract(refreshLeeway));
  }

  /// Called at startup: restores a stored session, signs out, or goes offline.
  Future<void> restore() => _inflightRestore ??= _restoreTracked();

  bool _restoring = false;

  Future<void> _restoreTracked() async {
    _restoring = true;
    try {
      await _restore();
    } finally {
      _restoring = false;
    }
  }

  /// Retries a restore that ended offline.
  Future<void> retry() {
    if (_state is! SessionOffline) return Future.value();
    if (_inflightRestore != null && _restoring) return _inflightRestore!;
    _cancelTimer();
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
      if (_isDefinitiveRejection(e)) {
        await _signOutLocally();
        return;
      }
      _logTransient('restore', e);
      _set(const SessionOffline());
      _scheduleRetry(e.retryAfter);
    }
  }

  /// Stores a session returned by any sign-in endpoint.
  Future<void> setSession(Session session) => _apply(session);

  /// Call when the app returns to the foreground: retries an offline restore, refreshes an
  /// expired or expiring access token, otherwise re-arms the proactive timer (timers may not have
  /// run while suspended).
  Future<void> ensureFresh() async {
    if (_state is SessionOffline) return retry();
    if (_state is! SignedIn) return;
    if (accessTokenExpiresSoon) {
      await refresh();
    } else if (_inflightRefresh == null) {
      _scheduleProactive();
    }
  }

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
      if (_isDefinitiveRejection(e)) {
        await _signOutLocally();
        return false;
      }
      _logTransient('refresh', e);
      if (_state is SignedIn) _scheduleRetry(e.retryAfter);
      return false;
    }
  }

  /// Runs before a user-initiated sign-out clears the session (e.g. unregistering this
  /// device for push while the access token is still valid). Must not throw.
  Future<void> Function()? beforeSignOut;

  Future<void> signOut() async {
    if (_state is SignedIn) {
      try {
        await beforeSignOut?.call();
      } catch (_) {}
    }
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

  /// Clears the session without calling the server (e.g. after the account was deleted).
  Future<void> endSessionLocally() => _signOutLocally();

  /// Only the server saying the refresh token is invalid ends the session.
  static bool _isDefinitiveRejection(ApiException e) =>
      e.statusCode == 401 ||
      (e.statusCode == 400 && e.code == 'missing_fields');

  Future<void> _apply(Session session) async {
    await _storage.writeRefreshToken(session.refreshToken);
    _expiresAt = _expiryOf(session);
    _retryAttempt = 0;
    _set(SignedIn(session));
    _scheduleProactive();
  }

  DateTime? _expiryOf(Session session) {
    final now = _clock.now();
    final byLifetime = session.expiresIn > 0
        ? now.add(Duration(seconds: session.expiresIn))
        : null;
    if (session.expiresAt <= 0) return byLifetime;
    final byTimestamp = DateTime.fromMillisecondsSinceEpoch(
      session.expiresAt * 1000,
      isUtc: true,
    );
    // A just-issued token can't already be expiring; if it looks that way the clock is off,
    // and trusting it would refresh in a loop.
    if (byLifetime != null &&
        byTimestamp.isBefore(now.add(refreshLeeway)) &&
        byLifetime.isAfter(now.add(refreshLeeway))) {
      return byLifetime;
    }
    return byTimestamp;
  }

  void _scheduleProactive() {
    final expiresAt = _expiresAt;
    if (expiresAt == null) {
      _cancelTimer();
      return;
    }
    final wait = expiresAt.subtract(refreshLeeway).difference(_clock.now());
    _arm(wait.isNegative ? Duration.zero : wait);
  }

  void _scheduleRetry(Duration? retryAfter) {
    final backoffMs = min(
      minRetryDelay.inMilliseconds * pow(2, min(_retryAttempt, 16)),
      maxRetryDelay.inMilliseconds,
    ).toInt();
    _retryAttempt++;
    final backoff = Duration(milliseconds: backoffMs);
    _arm(retryAfter != null && retryAfter > backoff ? retryAfter : backoff);
  }

  void _arm(Duration delay) {
    _cancelTimer();
    if (_disposed) return;
    _timer = _startTimer(delay, () {
      _timer = null;
      switch (_state) {
        case SignedIn():
          unawaited(refresh());
        case SessionOffline():
          unawaited(retry());
        default:
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _signOutLocally() async {
    _cancelTimer();
    _expiresAt = null;
    _retryAttempt = 0;
    await _storage.clear();
    _set(const SignedOut());
  }

  void _set(SessionState next) {
    _state = next;
    if (!_disposed) notifyListeners();
  }

  void _logTransient(String what, ApiException e) {
    if (kDebugMode) {
      debugPrint(
        'session: $what failed transiently (status ${e.statusCode}, code ${e.code}); session kept',
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimer();
    super.dispose();
  }
}
