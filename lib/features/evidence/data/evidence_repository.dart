import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import 'evidence_models.dart';

abstract class EvidenceRepository {
  Future<List<EvidenceEvent>> chain(String orderId);

  Future<ChainVerification> verify(String orderId);

  /// Multipart upload; [sha256] is the hex SHA-256 computed on the device (422 hash_mismatch
  /// when the server's hash of the bytes differs).
  Future<EvidenceMedia> uploadPhoto(
    String orderId, {
    required MediaKind kind,
    required List<int> bytes,
    required String fileName,
    required String sha256,
    void Function(int sent, int total)? onProgress,
  });

  /// The photo's bytes, streamed by Go to order parties only.
  Future<Uint8List> photo(String orderId, String mediaId);
}

class ApiEvidenceRepository implements EvidenceRepository {
  ApiEvidenceRepository(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(Object? data) =>
      (data as Map).cast<String, dynamic>();

  @override
  Future<List<EvidenceEvent>> chain(String orderId) async {
    final data = _map(await _api.get('orders/$orderId/evidence'));
    final events = [
      for (final e in (data['events'] as List? ?? const []))
        EvidenceEvent.fromJson(_map(e)),
    ]..sort((a, b) => a.seq.compareTo(b.seq));
    return events;
  }

  @override
  Future<ChainVerification> verify(String orderId) async =>
      ChainVerification.fromJson(
        _map(await _api.get('orders/$orderId/evidence/verify')),
      );

  @override
  Future<EvidenceMedia> uploadPhoto(
    String orderId, {
    required MediaKind kind,
    required List<int> bytes,
    required String fileName,
    required String sha256,
    void Function(int sent, int total)? onProgress,
  }) async => EvidenceMedia.fromJson(
    _map(
      await _api.postMultipart(
        'orders/$orderId/evidence/media',
        fields: {'kind': kind.wire, 'sha256': sha256},
        fileBytes: bytes,
        fileName: fileName,
        onProgress: onProgress,
      ),
    ),
  );

  @override
  Future<Uint8List> photo(String orderId, String mediaId) =>
      _api.getBytes('orders/$orderId/evidence/media/$mediaId');
}
