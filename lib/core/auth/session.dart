/// The backend's session response, shared by every sign-in method.
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.expiresAt,
    required this.tokenType,
    required this.user,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
    expiresAt: (json['expires_at'] as num?)?.toInt() ?? 0,
    tokenType: json['token_type'] as String? ?? 'bearer',
    user: SessionUser.fromJson(
      (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  /// Unix seconds.
  final int expiresAt;
  final String tokenType;
  final SessionUser user;

  @override
  String toString() => 'Session(user: ${user.id})';
}

class SessionUser {
  const SessionUser({required this.id, this.email});

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
    id: json['id'] as String? ?? '',
    email: json['email'] as String?,
  );

  final String id;
  final String? email;
}

sealed class SessionState {
  const SessionState();
}

/// Startup, before the stored refresh token has been checked.
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SignedOut extends SessionState {
  const SignedOut();
}

class SignedIn extends SessionState {
  const SignedIn(this.session);
  final Session session;
}
