import '../../l10n/app_localizations.dart';
import '../rider/rider_labels.dart' show formatDateTime;
import 'data/restriction_models.dart';

String suspensionReasonText(AppLocalizations l, SuspensionReason r) =>
    switch (r) {
      SuspensionReason.safetyIncident => l.suspensionReasonSafetyIncident,
      SuspensionReason.fraudOrFakeDocuments => l.suspensionReasonFraud,
      SuspensionReason.harassmentOrAbuse => l.suspensionReasonHarassment,
      SuspensionReason.repeatedNonPayment => l.suspensionReasonNonPayment,
      SuspensionReason.repeatedNoShows => l.suspensionReasonNoShows,
      SuspensionReason.strikes => l.suspensionReasonStrikes,
      SuspensionReason.other => l.suspensionReasonOther,
    };

String strikeReasonText(AppLocalizations l, StrikeReason? r) => switch (r) {
  StrikeReason.unpaidOrder => l.strikeReasonUnpaidOrder,
  StrikeReason.falsePaymentReport => l.strikeReasonFalseReport,
  null => l.strikeReasonGeneric,
};

/// Ensures the admin's message reads as its own sentence.
String _sentence(String s) => RegExp(r'[.!?]$').hasMatch(s) ? s : '$s.';

/// The suspension notice (D6 + amendments):
/// - in force: "Your account is suspended until 14 Oct, 15:30. Reason: Safety incident. [message]"
/// - safety/fraud hold: "Your account is on hold pending review. Reason: ... [message]"
/// - intended: "RideLink intends to suspend your account. Reason: ... [message] You can respond
///   until 14 Oct, 15:30."
String suspensionSummary(AppLocalizations l, AccountStatus s) {
  final until = s.until;
  final reason = s.reason;
  final respondBy = s.respondBy;
  final String lead;
  if (s.intended) {
    lead = l.suspensionIntendedLead;
  } else if (s.onHold) {
    lead = l.accountOnHold;
  } else if (until != null) {
    lead = l.accountSuspendedUntil(formatDateTime(l, until));
  } else if (s.permanent) {
    lead = l.accountSuspendedPermanent;
  } else {
    lead = l.accountSuspendedAfterOrder;
  }
  return [
    lead,
    if (reason != null)
      l.accountSuspendedReason(suspensionReasonText(l, reason)),
    if (s.message != null) _sentence(s.message!),
    if (s.intended && respondBy != null)
      l.suspensionRespondUntil(formatDateTime(l, respondBy)),
  ].join(' ');
}
