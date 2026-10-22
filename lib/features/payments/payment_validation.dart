import 'data/payment_models.dart';

/// Client-side mirror of the server's payment-method checks.
enum PaymentFieldError { required, tillInvalid, phoneInvalid, nameInvalid }

final _till = RegExp(r'^[0-9]{5,8}$');
final _subscriber = RegExp(r'^[71][0-9]{8}$');
final _mpesaCode = RegExp(r'^[A-Z0-9]{10}$');

/// Till numbers: digits only, 5 to 8 of them.
String? normalizeTill(String raw) {
  final s = raw.trim();
  return _till.hasMatch(s) ? s : null;
}

/// Kenyan mobile (07.., 01.., 254.., +254..) as "+2547XXXXXXXX", like the server's phone package.
String? normalizeKenyanMobile(String raw) {
  final s = raw.trim().replaceAll(' ', '').replaceAll('-', '');
  final String rest;
  if (s.startsWith('+254')) {
    rest = s.substring(4);
  } else if (s.startsWith('254')) {
    rest = s.substring(3);
  } else if (s.startsWith('0')) {
    rest = s.substring(1);
  } else {
    return null;
  }
  return _subscriber.hasMatch(rest) ? '+254$rest' : null;
}

/// Trimmed, 2 to 60 characters.
String? normalizeAccountName(String raw) {
  final s = raw.trim();
  final n = s.runes.length;
  return n >= 2 && n <= 60 ? s : null;
}

/// Uppercased M-Pesa transaction code (10 letters or digits), or null when invalid.
String? normalizeMpesaCode(String raw) {
  final s = raw.trim().toUpperCase();
  return _mpesaCode.hasMatch(s) ? s : null;
}

typedef MethodInput = ({
  String? number,
  String? accountName,
  PaymentFieldError? numberError,
  PaymentFieldError? nameError,
});

/// Normalized values for PUT /riders/me/payment-methods/{type}, or the field errors.
MethodInput validateMethodInput(PayMethod type, String number, String name) {
  final String? n;
  PaymentFieldError? numberError;
  if (number.trim().isEmpty) {
    n = null;
    numberError = PaymentFieldError.required;
  } else if (type == PayMethod.mpesaTill) {
    n = normalizeTill(number);
    if (n == null) numberError = PaymentFieldError.tillInvalid;
  } else {
    n = normalizeKenyanMobile(number);
    if (n == null) numberError = PaymentFieldError.phoneInvalid;
  }
  final String? a;
  PaymentFieldError? nameError;
  if (name.trim().isEmpty) {
    a = null;
    nameError = PaymentFieldError.required;
  } else {
    a = normalizeAccountName(name);
    if (a == null) nameError = PaymentFieldError.nameInvalid;
  }
  return (
    number: n,
    accountName: a,
    numberError: numberError,
    nameError: nameError,
  );
}

/// The optional M-Pesa code to send with [method]: null when empty or not M-Pesa.
/// Returns `(code, valid)`; `valid` is false when a non-empty code is malformed.
({String? code, bool valid}) mpesaCodeFor(PayMethod method, String raw) {
  if (!method.isMpesa || raw.trim().isEmpty) return (code: null, valid: true);
  final code = normalizeMpesaCode(raw);
  return (code: code, valid: code != null);
}
