import '../../l10n/app_localizations.dart';
import '../api/api_exception.dart';

/// Every machine-readable code in the backend's respond/codes.go (a stable contract: add, never rename).
const knownErrorCodes = <String>[
  'invalid_request',
  'unauthorized',
  'forbidden',
  'not_found',
  'conflict',
  'invalid_status',
  'file_too_large',
  'rate_limited',
  'internal_error',
  'upstream_unavailable',
  'service_unavailable',
  'invalid_email',
  'invalid_name',
  'missing_fields',
  'password_too_short',
  'password_too_long',
  'password_breached',
  'password_reused',
  'invalid_credentials',
  'invalid_code',
  'session_expired',
  'email_not_confirmed',
  'errand_unavailable',
  'unknown_category',
  'category_not_allowed',
  'order_not_editable',
  'order_not_cancellable',
  'order_unavailable',
  'no_active_offer',
  'offer_not_for_you',
  'rider_not_available',
  'rider_not_found',
  'rider_already_registered',
  'rider_not_verified',
  'documents_missing',
  'rider_paused',
  'location_required',
  'location_stale',
  'too_far_from_pickup',
  'pickup_window_passed',
  'already_arrived',
  'value_out_of_range',
  'invalid_file_type',
  'photo_not_found',
  'already_rated',
  'maps_unavailable',
  'no_agreed_price',
  'reserved_event_type',
  'invalid_media_kind',
  'invalid_hash',
  'hash_mismatch',
  'evidence_photo_required',
  'account_deleted',
  'account_has_active_order',
  'legal_acceptance_required',
  'payment_details_hidden',
];

/// The localized message for a server error code, or null for a code this build doesn't know.
/// [body] is the error body, for codes whose message depends on a field (e.g. `kind`).
String? errorCodeMessage(
  String code,
  AppLocalizations l, {
  Map<String, dynamic> body = const {},
}) => switch (code) {
  'invalid_request' => l.errCodeInvalidRequest,
  'unauthorized' => l.errCodeUnauthorized,
  'forbidden' => l.errCodeForbidden,
  'not_found' => l.errCodeNotFound,
  'conflict' => l.errCodeConflict,
  'invalid_status' => l.errCodeInvalidStatus,
  'file_too_large' => l.errCodeFileTooLarge,
  'rate_limited' => l.errorTooManyAttempts,
  'internal_error' => l.errCodeInternalError,
  'upstream_unavailable' => l.errCodeUpstreamUnavailable,
  'service_unavailable' => l.errCodeServiceUnavailable,
  'invalid_email' => l.errorEmailInvalid,
  'invalid_name' => l.errCodeInvalidName,
  'missing_fields' => l.errCodeMissingFields,
  'password_too_short' => l.errorPasswordTooShort,
  'password_too_long' => l.errorPasswordTooLong,
  'password_breached' => l.errCodePasswordBreached,
  'password_reused' => l.errCodePasswordReused,
  'invalid_credentials' => l.errorWrongCredentials,
  'invalid_code' => l.errorInvalidCode,
  'session_expired' => l.errCodeSessionExpired,
  'email_not_confirmed' => l.errCodeEmailNotConfirmed,
  'errand_unavailable' => l.errCodeErrandUnavailable,
  'unknown_category' => l.errCodeUnknownCategory,
  'category_not_allowed' => l.errCodeCategoryNotAllowed,
  'order_not_editable' => l.errCodeOrderNotEditable,
  'order_not_cancellable' => l.errCodeOrderNotCancellable,
  'order_unavailable' => l.errCodeOrderUnavailable,
  'no_active_offer' => l.errCodeNoActiveOffer,
  'offer_not_for_you' => l.errCodeOfferNotForYou,
  'rider_not_available' => l.errCodeRiderNotAvailable,
  'rider_not_found' => l.errCodeRiderNotFound,
  'rider_already_registered' => l.errCodeRiderAlreadyRegistered,
  'rider_not_verified' => l.errCodeRiderNotVerified,
  'documents_missing' => l.errCodeDocumentsMissing,
  'rider_paused' => l.errCodeRiderPaused,
  'location_required' => l.errCodeLocationRequired,
  'location_stale' => l.errCodeLocationStale,
  'too_far_from_pickup' => l.errCodeTooFarFromPickup,
  'pickup_window_passed' => l.errCodePickupWindowPassed,
  'already_arrived' => l.errCodeAlreadyArrived,
  'value_out_of_range' => l.errCodeValueOutOfRange,
  'invalid_file_type' => l.errCodeInvalidFileType,
  'photo_not_found' => l.errCodePhotoNotFound,
  'already_rated' => l.errCodeAlreadyRated,
  'maps_unavailable' => l.placeSearchUnavailable,
  'no_agreed_price' => l.errCodeNoAgreedPrice,
  'reserved_event_type' => l.errCodeReservedEventType,
  'invalid_media_kind' => l.errCodeInvalidMediaKind,
  'invalid_hash' => l.errCodeInvalidHash,
  'hash_mismatch' => l.errCodeHashMismatch,
  'evidence_photo_required' => switch (body['kind']) {
    'pickup_photo' => l.errCodeEvidencePickupPhotoRequired,
    'handover_photo' => l.errCodeEvidenceHandoverPhotoRequired,
    _ => l.errCodeEvidencePhotoRequired,
  },
  'account_deleted' => l.errCodeAccountDeleted,
  'account_has_active_order' => l.errCodeAccountHasActiveOrder,
  'legal_acceptance_required' => l.errCodeLegalAcceptanceRequired,
  'payment_details_hidden' => l.errCodePaymentDetailsHidden,
  _ => null,
};

const _serverSideCodes = {
  'internal_error',
  'upstream_unavailable',
  'service_unavailable',
};

/// What to show for a failed call. Known codes are localized; an unknown code shows the
/// server's own text. [fallback] (e.g. "Couldn't save") replaces network and server-side
/// failures, which say nothing specific about the action.
String apiErrorText(Object error, AppLocalizations l, {String? fallback}) {
  if (error is! ApiException) return fallback ?? l.errorGeneric;
  if (error.isNetworkError) return fallback ?? l.errorNetwork;
  final code = error.code;
  final status = error.statusCode ?? 500;
  if (fallback != null &&
      (status >= 500 || (code != null && _serverSideCodes.contains(code)))) {
    return fallback;
  }
  if (code != null) {
    final known = errorCodeMessage(code, l, body: error.body);
    if (known != null) return known;
    if (error.message.isNotEmpty) return error.message;
  }
  final statusCode = _codeForStatus(status);
  final byStatus = statusCode == null ? null : errorCodeMessage(statusCode, l);
  return fallback ?? byStatus ?? l.errorGeneric;
}

/// The message for a 409 on an order action. Codes this build doesn't know (the backend may add
/// more) fall back to the generic conflict message rather than the server's English text.
String conflictText(ApiException error, AppLocalizations l) {
  final code = error.code;
  return (code == null ? null : errorCodeMessage(code, l, body: error.body)) ??
      l.errCodeConflict;
}

/// The server's fallback code for a bare status (respond.codeForStatus), for older responses.
String? _codeForStatus(int status) => switch (status) {
  400 => 'invalid_request',
  401 => 'unauthorized',
  403 => 'forbidden',
  404 => 'not_found',
  409 => 'conflict',
  413 => 'file_too_large',
  422 => 'invalid_status',
  429 => 'rate_limited',
  502 => 'upstream_unavailable',
  503 => 'service_unavailable',
  500 => 'internal_error',
  _ => null,
};
