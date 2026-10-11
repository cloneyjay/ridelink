import 'package:google_sign_in/google_sign_in.dart';

import '../../core/auth/nonce.dart';

class GoogleCredential {
  const GoogleCredential({required this.idToken, required this.rawNonce});
  final String idToken;
  final String rawNonce;
}

class GoogleAuthFailure implements Exception {
  const GoogleAuthFailure([this.detail]);
  final String? detail;

  @override
  String toString() => 'GoogleAuthFailure($detail)';
}

/// Native Google sign-in that yields an ID token for POST /v1/auth/google.
abstract interface class GoogleAuth {
  /// False until GOOGLE_SERVER_CLIENT_ID is set; the button is hidden then.
  bool get isConfigured;

  /// Null when the user cancels; throws [GoogleAuthFailure] otherwise.
  Future<GoogleCredential?> signIn();
}

class GoogleSignInAuth implements GoogleAuth {
  GoogleSignInAuth(this._serverClientId);

  final String? _serverClientId;
  Future<String>? _init;

  @override
  bool get isConfigured => _serverClientId != null;

  @override
  Future<GoogleCredential?> signIn() async {
    // google_sign_in v7 is initialized once per process, so one nonce covers the session.
    final rawNonce = await (_init ??= _initialize());
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const GoogleAuthFailure('missing id token');
      return GoogleCredential(idToken: idToken, rawNonce: rawNonce);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw GoogleAuthFailure(e.code.name);
    }
  }

  Future<String> _initialize() async {
    final rawNonce = generateRawNonce();
    await GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId,
      nonce: sha256Hex(rawNonce),
    );
    return rawNonce;
  }
}
