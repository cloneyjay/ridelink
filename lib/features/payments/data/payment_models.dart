import '../../booking/data/booking_models.dart' show parseTime;

/// How a payer paid the rider directly. Every rider accepts cash; the M-Pesa methods are optional.
enum PayMethod {
  cash('cash'),
  mpesaTill('mpesa_till'),
  mpesaPochi('mpesa_pochi'),
  mpesaSendMoney('mpesa_send_money');

  const PayMethod(this.wire);
  final String wire;

  bool get isMpesa => this != cash;

  /// Pochi and Send Money pay to a mobile number; a till has its own number.
  bool get isMobile => this == mpesaPochi || this == mpesaSendMoney;

  /// The methods a rider can add (cash needs no setup).
  static const mpesa = [mpesaTill, mpesaPochi, mpesaSendMoney];

  static PayMethod? fromWire(String? value) {
    for (final m in values) {
      if (m.wire == value) return m;
    }
    return null;
  }
}

/// One of the rider's M-Pesa methods: their own list, or an order's snapshot.
class PaymentMethod {
  const PaymentMethod({
    required this.type,
    required this.number,
    required this.accountName,
    this.updatedAt,
  });

  final PayMethod type;
  final String number;
  final String accountName;
  final DateTime? updatedAt;

  /// Null for a type this build doesn't know (or cash, which is never a stored method).
  static PaymentMethod? tryParse(Object? json) {
    if (json is! Map) return null;
    final type = PayMethod.fromWire(json['type'] as String?);
    if (type == null || !type.isMpesa) return null;
    return PaymentMethod(
      type: type,
      number: json['number'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      updatedAt: parseTime(json['updated_at']),
    );
  }
}

List<PaymentMethod> parsePaymentMethods(Object? list) => [
  for (final m in (list is List ? list : const [])) ?PaymentMethod.tryParse(m),
]..sort((a, b) => a.type.index.compareTo(b.type.index));

/// GET /orders/{id}/payment: what the payer can pay with on this order (snapshot at acceptance).
class OrderPayment {
  const OrderPayment({
    required this.amount,
    required this.currency,
    required this.cash,
    required this.methods,
    this.methodTypes = const [],
    this.payerResponse,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) => OrderPayment(
    amount: (json['amount'] as num?)?.round(),
    currency: json['currency'] as String? ?? 'KES',
    cash: json['cash'] as bool? ?? true,
    methods: parsePaymentMethods(json['methods']),
    methodTypes: [
      for (final t
          in (json['method_types'] is List
              ? json['method_types'] as List
              : const []))
        if (PayMethod.fromWire(t as String?) case final m? when m.isMpesa) m,
    ]..sort((a, b) => a.index.compareTo(b.index)),
    payerResponse: PayerResponseState.fromWire(
      json['payer_response'] as String?,
    ),
  );

  /// Null when the server has no amount for the order.
  final int? amount;
  final String currency;
  final bool cash;
  final List<PaymentMethod> methods;

  /// The snapshot's M-Pesa types, sent even when the numbers are hidden.
  final List<PayMethod> methodTypes;

  /// Sender on a not-paid order: whether the "Did you pay?" answer is still due.
  final PayerResponseState? payerResponse;

  /// What the payer can say they paid with: cash plus the snapshot's M-Pesa types.
  List<PayMethod> get payerChoices => [PayMethod.cash, ...methodTypes];

  /// What the rider can record as received: cash first, then the snapshot's M-Pesa methods.
  List<PayMethod> get choices => [
    if (cash) PayMethod.cash,
    for (final m in methods) m.type,
  ];
}

enum PayerResponseState {
  pending('pending'),
  answered('answered');

  const PayerResponseState(this.wire);
  final String wire;

  static PayerResponseState? fromWire(String? value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return null;
  }
}

/// The sender's one answer after the rider reported the order as not paid.
class PayerResponse {
  const PayerResponse.paid({required PayMethod this.method, this.mpesaCode})
    : paid = true;

  const PayerResponse.notPaid() : paid = false, method = null, mpesaCode = null;

  final bool paid;
  final PayMethod? method;
  final String? mpesaCode;

  Map<String, dynamic> toJson() => {
    'paid': paid,
    if (method != null) 'method': method!.wire,
    'mpesa_code': ?mpesaCode,
  };
}
