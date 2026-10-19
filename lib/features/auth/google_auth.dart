import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../../core/auth/nonce.dart';

/// Bundled official Google "G" mark (unaltered colors, per Google's sign-in branding guidelines).
const googleMarkAsset = 'assets/brand/google_g.svg';

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

/// Passes the server client id and the hashed nonce for the next authentication request.
typedef NonceSetter = Future<void> Function(
  String? serverClientId,
  String hashedNonce,
);

class GoogleSignInAuth implements GoogleAuth {
  GoogleSignInAuth(
    this._serverClientId, {
    bool? perAttemptNonce,
    NonceSetter? initialize,
    NonceSetter? setNonce,
  }) : _perAttemptNonce =
           perAttemptNonce ?? defaultTargetPlatform == TargetPlatform.android,
       _initializePlugin = initialize ?? _initializeOnce,
       _setNonce = setNonce ?? _setPlatformNonce;

  final String? _serverClientId;
  final bool _perAttemptNonce;
  final NonceSetter _initializePlugin;
  final NonceSetter _setNonce;
  Future<String>? _init;

  @override
  bool get isConfigured => _serverClientId != null;

  @override
  Future<GoogleCredential?> signIn() async {
    final rawNonce = await nextNonce();
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

  /// A fresh raw nonce for this attempt; its SHA-256 goes into the ID token request.
  ///
  /// google_sign_in v7's app-facing [GoogleSignIn.initialize] may run only once per process.
  /// On Android the platform implementation's `init` only stores the server client id and
  /// nonce for the next Credential Manager request, so re-running it through the platform
  /// interface before each attempt gives every sign-in its own nonce (OIDC best practice).
  /// Elsewhere one nonce covers the app session.
  @visibleForTesting
  Future<String> nextNonce() async {
    final first = _init == null;
    final sessionNonce = await (_init ??= _initialize());
    if (first || !_perAttemptNonce) return sessionNonce;
    final rawNonce = generateRawNonce();
    await _setNonce(_serverClientId, sha256Hex(rawNonce));
    return rawNonce;
  }

  Future<String> _initialize() async {
    final rawNonce = generateRawNonce();
    await _initializePlugin(_serverClientId, sha256Hex(rawNonce));
    return rawNonce;
  }

  static Future<void> _initializeOnce(String? serverClientId, String nonce) =>
      GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
        nonce: nonce,
      );

  static Future<void> _setPlatformNonce(String? serverClientId, String nonce) =>
      GoogleSignInPlatform.instance.init(
        InitParameters(serverClientId: serverClientId, nonce: nonce),
      );
}
