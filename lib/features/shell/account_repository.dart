import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../orders/data/order_models.dart';

abstract class AccountRepository {
  /// True when GET /riders/me returns 200, false on 404.
  Future<bool> isRider();

  Future<Profile> profile();

  /// PATCH /profile; a verified rider gets 403 (names change through support).
  Future<Profile> updateName({
    required String firstName,
    required String lastName,
  });
}

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this._api);

  final ApiClient _api;

  @override
  Future<bool> isRider() async {
    try {
      await _api.get('riders/me');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return false;
      rethrow;
    }
  }

  @override
  Future<Profile> profile() async =>
      Profile.fromJson((await _api.get('profile') as Map).cast());

  @override
  Future<Profile> updateName({
    required String firstName,
    required String lastName,
  }) async => Profile.fromJson(
    (await _api.patch(
      'profile',
      data: {'first_name': firstName, 'last_name': lastName},
    ) as Map).cast(),
  );
}
