import '../../booking/data/booking_models.dart' show parseTime;

/// Evidence photo kinds; each is also the event type that records the photo's hash.
enum MediaKind {
  pickupPhoto('pickup_photo'),
  handoverPhoto('handover_photo'),
  itemPhoto('item_photo');

  const MediaKind(this.wire);
  final String wire;

  static MediaKind? fromWire(String? value) {
    for (final k in values) {
      if (k.wire == value) return k;
    }
    return null;
  }
}

/// One link in the order's append-only hash chain.
class EvidenceEvent {
  const EvidenceEvent({
    required this.id,
    required this.seq,
    required this.eventType,
    required this.eventHash,
    this.actorId,
    this.payload = const {},
    this.serverReceivedAt,
    this.clientCapturedAt,
  });

  factory EvidenceEvent.fromJson(Map<String, dynamic> json) => EvidenceEvent(
    id: json['id'] as String? ?? '',
    seq: (json['seq'] as num? ?? 0).toInt(),
    eventType: json['event_type'] as String? ?? '',
    eventHash: json['event_hash'] as String? ?? '',
    actorId: json['actor_id'] as String?,
    payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    serverReceivedAt: parseTime(json['server_received_at']),
    clientCapturedAt: parseTime(json['client_captured_at']),
  );

  final String id;
  final int seq;
  final String eventType;
  final String eventHash;
  final String? actorId;
  final Map<String, dynamic> payload;
  final DateTime? serverReceivedAt;
  final DateTime? clientCapturedAt;

  MediaKind? get mediaKind => MediaKind.fromWire(eventType);

  /// The photo behind a photo event (`payload.media_id`).
  String? get mediaId =>
      payload['media_id'] is String ? payload['media_id'] as String : null;

  DateTime? get time => serverReceivedAt ?? clientCapturedAt;
}

/// GET /orders/{id}/evidence/verify: every hash recomputed on the server.
class ChainVerification {
  const ChainVerification({
    required this.valid,
    required this.eventCount,
    this.error,
  });

  factory ChainVerification.fromJson(Map<String, dynamic> json) =>
      ChainVerification(
        valid: json['valid'] as bool? ?? false,
        eventCount: (json['event_count'] as num? ?? 0).toInt(),
        error: json['error'] as String?,
      );

  final bool valid;
  final int eventCount;
  final String? error;
}

class EvidenceMedia {
  const EvidenceMedia({
    required this.id,
    required this.kind,
    required this.sha256,
  });

  factory EvidenceMedia.fromJson(Map<String, dynamic> json) => EvidenceMedia(
    id: json['id'] as String? ?? '',
    kind: MediaKind.fromWire(json['kind'] as String?) ?? MediaKind.itemPhoto,
    sha256: json['sha256'] as String? ?? '',
  );

  final String id;
  final MediaKind kind;
  final String sha256;
}
