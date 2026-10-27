import '../../core/format/money.dart';
import '../../core/push/push_payload.dart';
import '../../l10n/app_localizations.dart';
import '../restrictions/data/restriction_models.dart';
import '../restrictions/restriction_labels.dart';
import '../rider/data/rider_models.dart';
import '../rider/rider_labels.dart';
import 'data/notification_repository.dart';

/// The server's English body for `payment_not_paid` when the receiver was the payer.
const _notPaidReceiverServerBody =
    "Your rider says the receiver didn't pay. Tell us if it was paid.";

/// A reason text placed after a colon (none start with a proper noun).
String _midSentence(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

/// Localized title and body by notification type; unknown types (or missing data) fall back to
/// the server's English text.
({String title, String body}) notificationText(
  AppNotification n,
  AppLocalizations l,
) {
  final data = n.data;
  final amount = data['amount'] is num
      ? formatKes(data['amount'] as num)
      : null;
  final doc = DocType.fromWire(data['doc_type'] as String?);
  final docLabel = doc == null ? null : docName(l, doc);
  DateTime? date(String key) =>
      data[key] is String ? DateTime.tryParse(data[key] as String) : null;
  final fallback = (title: n.title, body: n.body);

  switch (n.type) {
    case 'payment_requested':
      return (
        title: l.notifPaymentRequestedTitle,
        body: amount == null
            ? l.notifPaymentRequestedBodyNoAmount
            : l.notifPaymentRequestedBody(amount),
      );
    // Legacy: the retired "I've paid" step.
    case 'payment_sent':
      return (
        title: l.notifPaymentSentTitle,
        body: amount == null
            ? l.notifPaymentSentBodyNoAmount
            : l.notifPaymentSentBody(amount),
      );
    case 'payment_confirmed':
      return (
        title: l.notifPaymentConfirmedTitle,
        body: l.notifPaymentConfirmedBody,
      );
    case 'payment_unresolved':
      return (
        title: l.notifPaymentUnresolvedTitle,
        body: l.notifPaymentUnresolvedBody,
      );
    case 'payment_not_paid':
      final receiverPaid =
          data['payer'] == 'receiver' ||
          n.body.trim() == _notPaidReceiverServerBody;
      return (
        title: l.notifPaymentNotPaidTitle,
        body: receiverPaid
            ? l.notifPaymentNotPaidReceiverBody
            : l.notifPaymentNotPaidBody,
      );
    case paymentReminderType:
      return (
        title: l.notifPaymentReminderTitle,
        body: l.notifPaymentReminderBody,
      );
    case paymentTimeoutRiderType:
      final until = date('late_report_until');
      return (
        title: l.notifOrderClosedTitle,
        body: until == null
            ? l.lateReportBodyNoDeadline
            : l.lateReportBody(formatDateTime(l, until)),
      );
    case paymentTimeoutSenderType:
      return (title: l.notifOrderCompleteTitle, body: l.notifOrderCompleteBody);
    case 'payer_payment_response':
      return (title: l.notifPayerResponseTitle, body: l.notifPayerResponseBody);
    case 'pickup_arrived':
      return (title: l.notifPickupArrivedTitle, body: l.notifPickupArrivedBody);
    case 'pickup_timeout':
      return (title: l.notifPickupTimeoutTitle, body: l.notifPickupTimeoutBody);
    case 'pickup_timeout_rider':
      return (
        title: l.notifPickupTimeoutRiderTitle,
        body: l.notifPickupTimeoutRiderBody,
      );
    case 'receiver_location_shared':
      return (
        title: l.notifReceiverLocationTitle,
        body: l.notifReceiverLocationBody,
      );
    case 'document_expiring':
      final days = data['days_left'];
      final on = date('expires_on');
      if (docLabel == null || days is! num || on == null) return fallback;
      return (
        title: l.notifDocumentExpiringTitle(docLabel, days.toInt()),
        body: l.notifDocumentExpiringBody(formatDate(l, on)),
      );
    case 'document_expired':
      if (docLabel == null) return fallback;
      return (
        title: l.notifDocumentExpiredTitle(docLabel),
        body: l.notifDocumentExpiredBody,
      );
    case documentApprovedType:
      if (docLabel == null) return fallback;
      return (
        title: l.notifDocumentApprovedTitle,
        body: l.notifDocumentApprovedBody(docLabel),
      );
    case documentRejectedType:
      final code = RejectionCode.fromWire(data['reason_code'] as String?);
      if (docLabel == null || code == null) return fallback;
      return (
        title: l.notifDocumentRejectedTitle,
        body: l.notifDocumentRejectedBody(
          docLabel,
          _midSentence(rejectionReasonText(l, code)),
        ),
      );
    case riderVerifiedType:
      return (title: l.notifRiderVerifiedTitle, body: l.notifRiderVerifiedBody);
    case paymentRuledType:
      return (title: l.notifPaymentRuledTitle, body: l.notifPaymentRuledBody);
    case balanceCreatedType:
      return (
        title: l.homeBalanceBannerTitle,
        body: amount == null
            ? l.notifBalanceCreatedBodyNoAmount
            : l.notifBalanceCreatedBody(amount),
      );
    case balanceSettledType:
      return (title: l.balanceSettledTitle, body: l.notifBalanceSettledBody);
    case balanceClaimReceivedType:
      return (title: l.notifBalanceClaimTitle, body: l.notifBalanceClaimBody);
    case strikeIssuedType:
      return (title: l.notifStrikeIssuedTitle, body: l.notifStrikeIssuedBody);
    case strikeDisputeDecidedType:
      return (
        title: l.notifDisputeDecidedTitle,
        body: switch (disputeDecisionFromNotification(data)) {
          DisputeStatus.upheld => l.disputeUpheld,
          DisputeStatus.rejected => l.disputeRejected,
          _ => l.notifDisputeDecidedBody,
        },
      );
    case accountSuspendedType:
      final s = suspensionFromNotification(data);
      final known = data.containsKey('until') || s.reason != null;
      return (
        title: s.onHold ? l.accountOnHoldTitle : l.accountSuspendedTitle,
        body: known ? suspensionSummary(l, s) : l.notifAccountSuspendedBody,
      );
    case suspensionIntendedType:
      return (title: l.suspensionIntendedTitle, body: l.suspensionIntendedLead);
    case suspensionLiftedType:
      return (
        title: l.notifSuspensionLiftedTitle,
        body: l.notifSuspensionLiftedBody,
      );
    case appealDecidedType:
      return (
        title: l.notifAppealDecidedTitle,
        body: switch (appealDecisionFromNotification(data)) {
          AppealStatus.upheld => l.appealUpheld,
          AppealStatus.lifted => l.appealLifted,
          _ => l.notifAppealDecidedBody,
        },
      );
    default:
      return fallback;
  }
}
