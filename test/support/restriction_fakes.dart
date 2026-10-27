import 'package:ridelink/features/restrictions/data/restriction_models.dart';
import 'package:ridelink/features/restrictions/data/restrictions_repository.dart';

/// Account standing served from memory; defaults: no balances, not suspended.
class FakeRestrictionsRepository implements RestrictionsRepository {
  List<OutstandingBalance> balances = const [];
  Object? balancesError;
  int balancesCalls = 0;

  AccountStatus status = AccountStatus.active;
  Object? statusError;
  int statusCalls = 0;

  final claims = <({String orderId, PaidClaim claim})>[];
  Object? claimError;

  final forgiven = <String>[];
  Object? forgiveError;

  final appeals = <String>[];
  Object? appealError;

  final disputes = <({String strikeId, String message})>[];
  Object? disputeError;

  final responses = <String>[];
  Object? responseError;

  /// Applied after a successful appeal / dispute / response, as the server would.
  AccountStatus? statusAfterSend;

  @override
  Future<List<OutstandingBalance>> outstandingBalances() async {
    balancesCalls++;
    if (balancesError != null) throw balancesError!;
    return balances;
  }

  @override
  Future<void> claimPaid(String orderId, PaidClaim claim) async {
    if (claimError != null) throw claimError!;
    claims.add((orderId: orderId, claim: claim));
    balances = [
      for (final b in balances)
        b.orderId == orderId
            ? OutstandingBalance(
                orderId: b.orderId,
                amount: b.amount,
                riderFirstName: b.riderFirstName,
                cash: b.cash,
                methods: b.methods,
                createdAt: b.createdAt,
                claimedAt: DateTime.utc(2026, 10, 24, 10),
              )
            : b,
    ];
  }

  @override
  Future<void> forgiveBalance(String orderId) async {
    if (forgiveError != null) throw forgiveError!;
    forgiven.add(orderId);
  }

  @override
  Future<AccountStatus> accountStatus() async {
    statusCalls++;
    if (statusError != null) throw statusError!;
    return status;
  }

  void _sent() {
    if (statusAfterSend != null) status = statusAfterSend!;
  }

  @override
  Future<void> appeal(String message) async {
    if (appealError != null) throw appealError!;
    appeals.add(message);
    _sent();
  }

  @override
  Future<void> disputeStrike(String strikeId, String message) async {
    if (disputeError != null) throw disputeError!;
    disputes.add((strikeId: strikeId, message: message));
    _sent();
  }

  @override
  Future<void> respondToSuspension(String message) async {
    if (responseError != null) throw responseError!;
    responses.add(message);
    _sent();
  }
}
