import '../../booking/data/booking_models.dart' show parseTime;
import '../../payments/data/payment_models.dart';

// Every M6 wire shape the app reads is parsed here, so aligning with the backend's final field
// names is a change to this file only.

/// Suspension reason category (D6). `strikes` is the third-warning one.
enum SuspensionReason {
  safetyIncident('safety_incident'),
  fraudOrFakeDocuments('fraud_or_fake_documents'),
  harassmentOrAbuse('harassment_or_abuse'),
  repeatedNonPayment('repeated_non_payment'),
  repeatedNoShows('repeated_no_shows'),
  strikes('strikes'),
  other('other');

  const SuspensionReason(this.wire);
  final String wire;

  static SuspensionReason? fromWire(Object? value) {
    for (final r in values) {
      if (r.wire == value) return r;
    }
    return null;
  }
}

enum AppealStatus {
  none('none'),
  pending('pending'),
  upheld('upheld'),
  lifted('lifted');

  const AppealStatus(this.wire);
  final String wire;

  static AppealStatus fromWire(Object? value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return none;
  }
}

class AppealState {
  const AppealState({this.status = AppealStatus.none, this.canAppeal = false});

  factory AppealState.fromJson(Object? json) {
    if (json is! Map) return const AppealState();
    return AppealState(
      status: AppealStatus.fromWire(json['status']),
      canAppeal: json['can_appeal'] == true,
    );
  }

  final AppealStatus status;
  final bool canAppeal;
}

/// Where a suspension stands: none, announced with time to respond (prior notice for 30-day and
/// permanent rider suspensions), or in force.
enum SuspensionPhase { none, intended, active }

/// Dispute of one warning: one per strike, within 7 days.
enum DisputeStatus {
  none('none'),
  pending('pending'),
  upheld('upheld'),
  rejected('rejected');

  const DisputeStatus(this.wire);
  final String wire;

  static DisputeStatus fromWire(Object? value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return none;
  }
}

/// Strike reasons the app names; anything else shows as a plain warning.
enum StrikeReason {
  unpaidOrder('non_payment'),
  falsePaymentReport('false_payment_report');

  const StrikeReason(this.wire);
  final String wire;

  static StrikeReason? fromWire(Object? value) {
    for (final r in values) {
      if (r.wire == value) return r;
    }
    return null;
  }
}

/// One active warning (never public).
class Strike {
  const Strike({
    required this.id,
    this.orderId,
    this.reason,
    this.issuedAt,
    this.expiresAt,
    this.dispute = DisputeStatus.none,
    this.canDispute = false,
  });

  factory Strike.fromJson(Map<String, dynamic> json) {
    final dispute = json['dispute'] is Map
        ? (json['dispute'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final orderId = json['order_id'];
    return Strike(
      id: json['id'] as String? ?? '',
      orderId: orderId is String && orderId.isNotEmpty ? orderId : null,
      reason: StrikeReason.fromWire(json['reason']),
      issuedAt: parseTime(json['issued_at']),
      expiresAt: parseTime(json['expires_at']),
      dispute: DisputeStatus.fromWire(dispute['status']),
      canDispute: dispute['can_dispute'] == true,
    );
  }

  final String id;
  final String? orderId;
  final StrikeReason? reason;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final DisputeStatus dispute;
  final bool canDispute;
}

/// GET /v1/me/account-status, or the extras on a 403 `account_suspended`.
class AccountStatus {
  const AccountStatus({
    required this.suspended,
    this.phase,
    this.until,
    this.reason,
    this.message,
    this.respondBy,
    this.canRespond = false,
    this.responseSent = false,
    this.appeal = const AppealState(),
    this.strikes = const [],
    this.permanentFlag,
    this.startsAfterCurrentOrder = false,
  });

  static const active = AccountStatus(suspended: false);

  factory AccountStatus.fromJson(Map<String, dynamic> json) {
    final suspended = json['suspended'] == true;
    final intended = json['status'] == 'intended';
    // Intended suspension: `intended: {respond_by, response_submitted, can_respond}`.
    final notice = json['intended'] is Map
        ? (json['intended'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final responseSent = notice['response_submitted'] == true;
    final permanent = json['permanent'];
    final message = json['message'];
    final strikes = json['strikes'];
    return AccountStatus(
      suspended: suspended,
      phase: intended
          ? SuspensionPhase.intended
          : suspended
          ? SuspensionPhase.active
          : SuspensionPhase.none,
      until: parseTime(json['until']),
      reason: SuspensionReason.fromWire(json['reason']),
      message: message is String && message.trim().isNotEmpty
          ? message.trim()
          : null,
      respondBy: parseTime(json['respond_by'] ?? notice['respond_by']),
      canRespond:
          intended &&
          !responseSent &&
          (notice['can_respond'] as bool? ?? true),
      responseSent: responseSent,
      permanentFlag: permanent is bool ? permanent : null,
      startsAfterCurrentOrder: json['starts_after_current_order'] == true,
      appeal: AppealState.fromJson(json['appeal']),
      strikes: [
        for (final st in (strikes is List ? strikes : const []))
          if (st is Map) Strike.fromJson(st.cast<String, dynamic>()),
      ],
    );
  }

  /// From a 403 `account_suspended` body (`until`, `reason`, `permanent`,
  /// `starts_after_current_order`); the appeal state isn't sent there.
  factory AccountStatus.fromSuspendedError(Map<String, dynamic> body) {
    final permanent = body['permanent'];
    return AccountStatus(
      suspended: true,
      phase: SuspensionPhase.active,
      until: parseTime(body['until']),
      reason: SuspensionReason.fromWire(body['reason']),
      permanentFlag: permanent is bool ? permanent : null,
      startsAfterCurrentOrder: body['starts_after_current_order'] == true,
    );
  }

  final bool suspended;
  final SuspensionPhase? phase;

  /// End of the suspension; null while permanent or not started yet.
  final DateTime? until;
  final SuspensionReason? reason;

  /// The admin's plain-language message to the person (not the internal note).
  final String? message;

  /// Intended suspension: the response deadline.
  final DateTime? respondBy;
  final bool canRespond;
  final bool responseSent;
  final AppealState appeal;
  final List<Strike> strikes;

  /// The server's `permanent`; when absent, a suspension without an end is permanent.
  final bool? permanentFlag;

  /// Waiting: the suspension starts when the current order ends (no end date yet).
  final bool startsAfterCurrentOrder;

  SuspensionPhase get effectivePhase =>
      phase ?? (suspended ? SuspensionPhase.active : SuspensionPhase.none);

  bool get intended => effectivePhase == SuspensionPhase.intended;

  bool get permanent =>
      suspended &&
      (permanentFlag ?? (until == null && !startsAfterCurrentOrder));

  /// Safety and fraud suspensions are immediate holds pending review.
  bool get onHold =>
      suspended &&
      (reason == SuspensionReason.safetyIncident ||
          reason == SuspensionReason.fraudOrFakeDocuments);
}

/// One open debt from GET /v1/me/outstanding-balances: the sender owes the rider for an order.
class OutstandingBalance {
  const OutstandingBalance({
    required this.orderId,
    required this.amount,
    required this.riderFirstName,
    required this.cash,
    required this.methods,
    this.createdAt,
    this.claimedAt,
    this.claimRejected = false,
  });

  factory OutstandingBalance.fromJson(Map<String, dynamic> json) {
    // The payment details may come flat or nested under "payment" (same shape as GET /payment).
    final payment = json['payment'] is Map
        ? (json['payment'] as Map).cast<String, dynamic>()
        : json;
    // The "I've paid" claim: `claim: {status: pending|rejected, method, claimed_at}`.
    final claim = json['claim'] is Map
        ? (json['claim'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return OutstandingBalance(
      orderId: json['order_id'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0).round(),
      riderFirstName: json['rider_first_name'] as String? ?? '',
      cash: payment['cash'] as bool? ?? true,
      methods: parsePaymentMethods(payment['methods']),
      createdAt: parseTime(json['created_at']),
      claimedAt: parseTime(claim['claimed_at'] ?? json['claimed_at']),
      claimRejected: claim['status'] == 'rejected',
    );
  }

  final String orderId;

  /// Whole KES (the agreed price).
  final int amount;
  final String riderFirstName;
  final bool cash;
  final List<PaymentMethod> methods;
  final DateTime? createdAt;

  /// When the payer said "I've paid"; the rider is then asked to confirm.
  final DateTime? claimedAt;

  /// Staff rejected the claim. One claim per balance, so "I've paid" isn't offered again.
  final bool claimRejected;

  /// A claim is waiting for the rider (or staff) to confirm.
  bool get claimed => claimedAt != null && !claimRejected;

  bool get canClaim => claimedAt == null;

  /// What the payer can say they paid with.
  List<PayMethod> get choices => [
    PayMethod.cash,
    for (final m in methods) m.type,
  ];
}

List<OutstandingBalance> parseOutstandingBalances(Object? data) {
  final list = data is Map ? data['balances'] : data;
  return [
    for (final b in (list is List ? list : const []))
      if (b is Map) OutstandingBalance.fromJson(b.cast<String, dynamic>()),
  ];
}

/// POST /me/outstanding-balances/{order_id}/paid.
class PaidClaim {
  const PaidClaim({required this.method, this.mpesaCode, this.note});

  final PayMethod method;
  final String? mpesaCode;

  /// Optional cash note (e.g. when and where it was paid).
  final String? note;

  Map<String, dynamic> toJson() => {
    'method': method.wire,
    'mpesa_code': ?mpesaCode,
    'note': ?note,
  };
}

const cashNoteMaxLength = 500;

/// GET /orders/{id}: whether this order still has an open outstanding balance (rider side:
/// "Payment received" or "Forgive balance" closes it).
bool parseBalanceOpen(Map<String, dynamic> orderJson) =>
    orderJson['balance_status'] == 'open';

/// `account_suspended` notification data (`until`, `reason`), when sent.
AccountStatus suspensionFromNotification(Map<String, dynamic> data) =>
    AccountStatus.fromSuspendedError(data);

/// `appeal_decided` notification data: `decision` is `upheld` or `lifted`.
AppealStatus appealDecisionFromNotification(Map<String, dynamic> data) =>
    AppealStatus.fromWire(data['decision']);

/// `strike_dispute_decided` notification data: `decision` is `upheld` or `rejected`.
DisputeStatus disputeDecisionFromNotification(Map<String, dynamic> data) =>
    DisputeStatus.fromWire(data['decision']);

/// Error codes from the M6 contract.
const outstandingBalanceCode = 'outstanding_balance';
const accountSuspendedCode = 'account_suspended';

/// Notification kinds from the M6 contract.
const paymentRuledType = 'payment_ruled';
const balanceCreatedType = 'balance_created';
const balanceSettledType = 'balance_settled';
const balanceClaimReceivedType = 'balance_claim_received';
const strikeIssuedType = 'strike_issued';
const strikeDisputeDecidedType = 'strike_dispute_decided';
const accountSuspendedType = 'account_suspended';
const suspensionIntendedType = 'suspension_intended';
const suspensionLiftedType = 'suspension_lifted';
const appealDecidedType = 'appeal_decided';

const balanceNotificationTypes = {
  balanceCreatedType,
  balanceSettledType,
  paymentRuledType,
};

/// Notifications that open the account status screen.
const accountNotificationTypes = {
  accountSuspendedType,
  suspensionIntendedType,
  suspensionLiftedType,
  appealDecidedType,
  strikeIssuedType,
  strikeDisputeDecidedType,
};
