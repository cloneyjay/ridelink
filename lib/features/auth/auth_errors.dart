import '../../core/api/api_exception.dart';
import '../../l10n/app_localizations.dart';

/// What a 401 means on the screen that made the call.
enum AuthUnauthorized { wrongCredentials, invalidCode, google }

/// 400s show the server's own message; everything else gets a friendly local string.
String authErrorMessage(
  ApiException e,
  AppLocalizations l, {
  AuthUnauthorized on401 = AuthUnauthorized.wrongCredentials,
}) {
  final status = e.statusCode;
  if (status == null) return l.errorNetwork;
  if (status == 400 && e.message.isNotEmpty) return e.message;
  if (status == 401) {
    return switch (on401) {
      AuthUnauthorized.wrongCredentials => l.errorWrongCredentials,
      AuthUnauthorized.invalidCode => l.errorInvalidCode,
      AuthUnauthorized.google => l.errorGoogleFailed,
    };
  }
  if (status == 429) return l.errorTooManyAttempts;
  if (status >= 500) return l.errorServiceUnavailable;
  return l.errorGeneric;
}
