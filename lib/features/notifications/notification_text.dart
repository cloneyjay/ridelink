import '../../core/format/money.dart';
import '../../l10n/app_localizations.dart';
import '../rider/data/rider_models.dart';
import '../rider/rider_labels.dart';
import 'data/notification_repository.dart';

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
        body: amount == null
            ? l.notifPaymentConfirmedBodyNoAmount
            : l.notifPaymentConfirmedBody(amount),
      );
    case 'payment_unresolved':
      return (
        title: l.notifPaymentUnresolvedTitle,
        body: l.notifPaymentUnresolvedBody,
      );
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
    default:
      return fallback;
  }
}
