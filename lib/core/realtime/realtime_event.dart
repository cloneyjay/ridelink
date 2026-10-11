import 'dart:convert';

enum RealtimeEventKind {
  connected('connected'),
  orderUpdated('order.updated'),
  offerReceived('offer.received'),
  offerResolved('offer.resolved'),
  notificationCreated('notification.created'),
  riderLocation('rider.location'),
  unknown('');

  const RealtimeEventKind(this.wireType);
  final String wireType;

  static RealtimeEventKind fromWire(String type) => values.firstWhere(
    (k) => k != unknown && k.wireType == type,
    orElse: () => unknown,
  );
}

/// One server-to-client message from GET /v1/ws: {"type": "...", "data": {...}}.
class RealtimeEvent {
  const RealtimeEvent({
    required this.type,
    required this.kind,
    this.data = const {},
  });

  final String type;
  final RealtimeEventKind kind;
  final Map<String, dynamic> data;

  /// Returns null for frames that aren't a typed JSON object.
  static RealtimeEvent? tryParse(Object? frame) {
    if (frame is! String) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(frame);
    } on FormatException {
      return null;
    }
    if (decoded is! Map || decoded['type'] is! String) return null;
    final type = decoded['type'] as String;
    final data = decoded['data'];
    return RealtimeEvent(
      type: type,
      kind: RealtimeEventKind.fromWire(type),
      data: data is Map ? data.cast<String, dynamic>() : const {},
    );
  }
}
