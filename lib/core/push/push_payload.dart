import 'dart:convert';

/// Push types that wake a rider for a time-limited offer (high-importance channel).
const offerReceivedType = 'offer.received';

/// A data-only push: `{"type","order_id","notification_id"}`. It never carries RideLink data;
/// the app fetches everything from the Go server after it opens.
class PushPayload {
  const PushPayload({required this.type, this.orderId, this.notificationId});

  /// Null when the message has no usable `type`.
  static PushPayload? fromData(Map<String, dynamic> data) {
    final type = data['type'];
    if (type is! String || type.isEmpty) return null;
    String? text(String key) {
      final v = data[key];
      return v is String && v.isNotEmpty ? v : null;
    }

    return PushPayload(
      type: type,
      orderId: text('order_id'),
      notificationId: text('notification_id'),
    );
  }

  /// The local notification's tap payload.
  static PushPayload? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map ? fromData(decoded.cast<String, dynamic>()) : null;
    } on FormatException {
      return null;
    }
  }

  final String type;
  final String? orderId;
  final String? notificationId;

  bool get isOffer => type == offerReceivedType;

  String encode() => jsonEncode({
    'type': type,
    'order_id': ?orderId,
    'notification_id': ?notificationId,
  });

  /// One system notification per order (a newer push replaces the older one).
  int get notificationTag =>
      (orderId ?? notificationId ?? type).hashCode & 0x7fffffff;
}
