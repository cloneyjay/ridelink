import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const _nonceAlphabet =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';

/// A random raw nonce from a cryptographically secure source.
String generateRawNonce({int length = 32, Random? random}) {
  final rng = random ?? Random.secure();
  return List.generate(
    length,
    (_) => _nonceAlphabet[rng.nextInt(_nonceAlphabet.length)],
  ).join();
}

/// Lowercase hex SHA-256, the form Google puts in the ID token's nonce claim.
String sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();
