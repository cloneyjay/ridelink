import '../../../core/api/api_client.dart';
import 'restriction_models.dart';

/// The signed-in user's account standing: open balances, warnings, suspension and appeal.
abstract class RestrictionsRepository {
  /// GET /me/outstanding-balances.
  Future<List<OutstandingBalance>> outstandingBalances();

  /// POST /me/outstanding-balances/{order_id}/paid: the payer says they paid; the rider is
  /// asked to confirm and a review case opens.
  Future<void> claimPaid(String orderId, PaidClaim claim);

  /// POST /orders/{id}/balance/forgive (rider of that order).
  Future<void> forgiveBalance(String orderId);

  /// GET /me/account-status.
  Future<AccountStatus> accountStatus();

  /// POST /me/appeal: one per suspension.
  Future<void> appeal(String message);

  /// POST /me/strikes/{id}/dispute: one per strike, within 7 days.
  Future<void> disputeStrike(String strikeId, String message);

  /// POST /me/suspension-response: reply to an intended suspension before `respond_by`.
  Future<void> respondToSuspension(String message);
}

/// Appeal, dispute and response messages (server limit).
const appealMaxLength = 1000;

class ApiRestrictionsRepository implements RestrictionsRepository {
  ApiRestrictionsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<OutstandingBalance>> outstandingBalances() async =>
      parseOutstandingBalances(await _api.get('me/outstanding-balances'));

  @override
  Future<void> claimPaid(String orderId, PaidClaim claim) async {
    await _api.post(
      'me/outstanding-balances/$orderId/paid',
      data: claim.toJson(),
    );
  }

  @override
  Future<void> forgiveBalance(String orderId) async {
    await _api.post('orders/$orderId/balance/forgive');
  }

  @override
  Future<AccountStatus> accountStatus() async => AccountStatus.fromJson(
    (await _api.get('me/account-status') as Map).cast<String, dynamic>(),
  );

  @override
  Future<void> appeal(String message) async {
    await _api.post('me/appeal', data: {'message': message});
  }

  @override
  Future<void> disputeStrike(String strikeId, String message) async {
    await _api.post('me/strikes/$strikeId/dispute', data: {'message': message});
  }

  @override
  Future<void> respondToSuspension(String message) async {
    await _api.post('me/suspension-response', data: {'message': message});
  }
}
