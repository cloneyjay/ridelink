import '../../core/api/api_exception.dart';
import '../../core/errors/error_messages.dart';
import '../../l10n/app_localizations.dart';

/// What a 401 means on the screen that made the call.
enum AuthUnauthorized { wrongCredentials, invalidCode, google }

/// Error codes are localized; a 401 without a specific code takes the screen's meaning.
String authErrorMessage(
  ApiException e,
  AppLocalizations l, {
  AuthUnauthorized on401 = AuthUnauthorized.wrongCredentials,
}) {
  final status = e.statusCode;
  if (status == null) return l.errorNetwork;
  if (status == 401) {
    if (on401 == AuthUnauthorized.google) return l.errorGoogleFailed;
    if (e.code == null || e.code == 'unauthorized') {
      return on401 == AuthUnauthorized.invalidCode
          ? l.errorInvalidCode
          : l.errorWrongCredentials;
    }
  }
  if (status >= 500) return l.errorServiceUnavailable;
  return apiErrorText(e, l);
}
