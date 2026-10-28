import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import 'public_profile_models.dart';

abstract class PublicProfileRepository {
  /// GET /senders/{id}/public-profile; 404 when the rider may no longer see it.
  Future<PublicProfile> sender(String id);

  /// GET /senders/{id}/photo as bytes; null when there is none (404).
  Future<Uint8List?> senderPhoto(String id);

  /// GET /riders/{id}/public-profile.
  Future<PublicProfile> rider(String id);

  /// GET /me/public-profile?role=…; 404 for `rider` without a rider profile.
  Future<PublicProfile> mine(PublicProfileRole role);
}

class ApiPublicProfileRepository implements PublicProfileRepository {
  ApiPublicProfileRepository(this._api);

  final ApiClient _api;

  static PublicProfile _parse(Object? data) =>
      PublicProfile.fromJson((data as Map).cast<String, dynamic>());

  @override
  Future<PublicProfile> sender(String id) async =>
      _parse(await _api.get('senders/$id/public-profile'));

  @override
  Future<Uint8List?> senderPhoto(String id) async {
    try {
      return await _api.getBytes('senders/$id/photo');
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<PublicProfile> rider(String id) async =>
      _parse(await _api.get('riders/$id/public-profile'));

  @override
  Future<PublicProfile> mine(PublicProfileRole role) async =>
      _parse(await _api.get('me/public-profile', query: {'role': role.wire}));
}
