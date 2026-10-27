import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'account_status_screen.dart';
import 'restriction_providers.dart';

/// Sender: "Settle your balance" while the signed-in user owes the rider on [orderId].
class SettleBalanceLink extends ConsumerWidget {
  const SettleBalanceLink({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(balanceForOrderProvider(orderId)) == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: OutlinedButton.icon(
        key: const Key('settleBalance.link'),
        onPressed: () => context.push(AppRoutes.settleBalance),
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: Text(AppLocalizations.of(context).settleBalanceTitle),
      ),
    );
  }
}

/// Sender home: the open balance (total) and the suspension, each opening its screen.
class HomeRestrictionBanners extends ConsumerWidget {
  const HomeRestrictionBanners({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(accountStatusProvider).value;
    final balances = ref.watch(outstandingBalancesProvider).value ?? const [];
    final total = balances.fold<int>(0, (sum, b) => sum + b.amount);
    final children = <Widget>[
      if (status != null && (status.suspended || status.intended))
        SuspensionCard(
          key: const Key('home.suspended'),
          status: status,
          action: TextButton(
            key: const Key('home.suspended.details'),
            onPressed: () => context.push(AppRoutes.accountStatus),
            child: Text(l.suspendedViewDetails),
          ),
        ),
      if (balances.isNotEmpty) _BalanceBanner(amount: formatKes(total)),
    ];
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, w) in children.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s2),
            w,
          ],
        ],
      ),
    );
  }
}

class _BalanceBanner extends StatelessWidget {
  const _BalanceBanner({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Material(
      color: c.statusErrorTint,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        key: const Key('home.balance'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push(AppRoutes.settleBalance),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: c.statusError,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.homeBalanceBannerTitle,
                        style: AppTextStyles.labelLg.copyWith(color: c.ink),
                      ),
                      Text(
                        l.homeBalanceBannerBody(amount),
                        key: const Key('home.balance.body'),
                        style: AppTextStyles.bodySm.copyWith(color: c.ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  l.viewButton,
                  style: AppTextStyles.label.copyWith(color: c.brand700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
