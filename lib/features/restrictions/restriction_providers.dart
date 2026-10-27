import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/realtime/realtime_event.dart';
import '../../core/routing/app_router.dart';
import 'data/restriction_models.dart';

/// A realtime event that should re-read account standing: a reconnect, or a notification of
/// one of [types].
bool _refreshesOn(RealtimeEvent? e, Set<String> types) {
  if (e == null) return false;
  if (e.kind == RealtimeEventKind.connected) return true;
  return e.kind == RealtimeEventKind.notificationCreated &&
      types.contains(e.data['type']);
}

/// The signed-in user's open balances (empty when signed out).
final outstandingBalancesProvider = FutureProvider<List<OutstandingBalance>>((
  ref,
) {
  if (ref.watch(currentUserIdProvider) == null) return const [];
  ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (_, next) {
    if (_refreshesOn(next.value, balanceNotificationTypes)) {
      ref.invalidateSelf();
    }
  });
  return ref.watch(restrictionsRepositoryProvider).outstandingBalances();
}, retry: (_, _) => null);

/// The signed-in user's suspension state (active when signed out).
final accountStatusProvider = FutureProvider<AccountStatus>((ref) {
  if (ref.watch(currentUserIdProvider) == null) return AccountStatus.active;
  ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (_, next) {
    if (_refreshesOn(next.value, accountNotificationTypes)) {
      ref.invalidateSelf();
    }
  });
  return ref.watch(restrictionsRepositoryProvider).accountStatus();
}, retry: (_, _) => null);

/// True when the last known status says suspended (unknown or failed reads count as not).
final isSuspendedProvider = Provider<bool>(
  (ref) => ref.watch(accountStatusProvider).value?.suspended ?? false,
);

/// The open balance for [orderId], if the signed-in user owes one.
final balanceForOrderProvider = Provider.family<OutstandingBalance?, String>(
  (ref, orderId) => ref
      .watch(outstandingBalancesProvider)
      .value
      ?.where((b) => b.orderId == orderId)
      .firstOrNull,
);

/// A blocked booking: 409 `outstanding_balance` opens the settle screen, 403 `account_suspended`
/// the suspension screen. Returns false for any other error.
bool openBlockScreen(BuildContext context, WidgetRef ref, Object error) {
  if (error is! ApiException) return false;
  if (error.code == outstandingBalanceCode) {
    ref.invalidate(outstandingBalancesProvider);
    context.push(AppRoutes.settleBalance);
    return true;
  }
  if (error.code == accountSuspendedCode) {
    ref.invalidate(accountStatusProvider);
    context.push(AppRoutes.accountStatus);
    return true;
  }
  return false;
}
