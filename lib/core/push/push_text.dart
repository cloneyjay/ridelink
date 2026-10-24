import '../../l10n/app_localizations.dart';
import 'push_payload.dart';

enum PushChannel {
  /// Rider offers: sound and heads-up.
  offers('ridelink.offers'),

  /// Everything else.
  updates('ridelink.updates');

  const PushChannel(this.id);
  final String id;

  String name(AppLocalizations l) =>
      this == offers ? l.pushChannelOffersName : l.pushChannelUpdatesName;

  String description(AppLocalizations l) => this == offers
      ? l.pushChannelOffersDescription
      : l.pushChannelUpdatesDescription;
}

PushChannel pushChannelFor(PushPayload p) =>
    p.isOffer ? PushChannel.offers : PushChannel.updates;

/// Generic localized text per push type. Pushes carry no amounts or names, so only text that
/// needs no data is used; unknown types get a neutral "open the app" message.
({String title, String body}) pushText(PushPayload p, AppLocalizations l) =>
    switch (p.type) {
      offerReceivedType => (title: l.pushOfferTitle, body: l.pushOfferBody),
      'payment_requested' => (
        title: l.notifPaymentRequestedTitle,
        body: l.notifPaymentRequestedBodyNoAmount,
      ),
      'payment_sent' => (
        title: l.notifPaymentSentTitle,
        body: l.notifPaymentSentBodyNoAmount,
      ),
      'payment_confirmed' => (
        title: l.notifPaymentConfirmedTitle,
        body: l.notifPaymentConfirmedBody,
      ),
      'payment_unresolved' => (
        title: l.notifPaymentUnresolvedTitle,
        body: l.notifPaymentUnresolvedBody,
      ),
      'payment_not_paid' => (
        title: l.notifPaymentNotPaidTitle,
        body: l.notifPaymentNotPaidBody,
      ),
      paymentReminderType => (
        title: l.notifPaymentReminderTitle,
        body: l.notifPaymentReminderBody,
      ),
      paymentTimeoutRiderType => (
        title: l.notifOrderClosedTitle,
        body: l.lateReportBodyNoDeadline,
      ),
      paymentTimeoutSenderType => (
        title: l.notifOrderCompleteTitle,
        body: l.notifOrderCompleteBody,
      ),
      'payer_payment_response' => (
        title: l.notifPayerResponseTitle,
        body: l.notifPayerResponseBody,
      ),
      'pickup_arrived' => (
        title: l.notifPickupArrivedTitle,
        body: l.notifPickupArrivedBody,
      ),
      'pickup_timeout' => (
        title: l.notifPickupTimeoutTitle,
        body: l.notifPickupTimeoutBody,
      ),
      'pickup_timeout_rider' => (
        title: l.notifPickupTimeoutRiderTitle,
        body: l.notifPickupTimeoutRiderBody,
      ),
      'receiver_location_shared' => (
        title: l.notifReceiverLocationTitle,
        body: l.notifReceiverLocationBody,
      ),
      'document_expiring' || 'document_expired' => (
        title: l.pushDocumentTitle,
        body: l.pushDocumentBody,
      ),
      _ => (title: l.pushGenericTitle, body: l.pushGenericBody),
    };
