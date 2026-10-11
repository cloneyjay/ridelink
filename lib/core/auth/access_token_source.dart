/// What the API and realtime clients need from the session.
abstract interface class AccessTokenSource {
  String? get accessToken;

  /// True while a session exists (even if the access token has expired).
  bool get hasSession;

  /// Rotates tokens; concurrent callers share one refresh. Returns false if it failed.
  Future<bool> refresh();
}
