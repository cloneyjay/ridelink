import 'dart:convert';

import '../../l10n/app_localizations.dart';

/// Mirrors the server: NIST SP 800-63B-4, 15 characters minimum, 72-byte bcrypt maximum.
const minPasswordChars = 15;
const maxPasswordBytes = 72;
const maxNameChars = 50;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool passwordLongEnough(String value) => value.runes.length >= minPasswordChars;

String? validateEmail(String? value, AppLocalizations l) =>
    _emailPattern.hasMatch((value ?? '').trim()) ? null : l.errorEmailInvalid;

String? validateFirstName(String? value, AppLocalizations l) =>
    _validateName(value, l, l.errorFirstNameRequired);

String? validateLastName(String? value, AppLocalizations l) =>
    _validateName(value, l, l.errorLastNameRequired);

String? _validateName(String? value, AppLocalizations l, String required) {
  final name = (value ?? '').trim();
  if (name.isEmpty) return required;
  if (name.runes.length > maxNameChars) return l.errorNameTooLong;
  return null;
}

/// For signing in: any non-empty password (old accounts may predate the rules).
String? validateExistingPassword(String? value, AppLocalizations l) =>
    (value ?? '').isEmpty ? l.errorPasswordRequired : null;

String? validateNewPassword(String? value, AppLocalizations l) {
  final password = value ?? '';
  if (!passwordLongEnough(password)) return l.errorPasswordTooShort;
  if (utf8.encode(password).length > maxPasswordBytes) {
    return l.errorPasswordTooLong;
  }
  return null;
}

String? validateCode(String? value, AppLocalizations l) =>
    RegExp(r'^\d{6}$').hasMatch(value ?? '') ? null : l.errorCodeFormat;
