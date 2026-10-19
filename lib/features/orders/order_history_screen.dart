import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/mode/app_mode.dart';
import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/booking_labels.dart';
import '../booking/data/booking_models.dart';
import '../booking/widgets/booking_widgets.dart';
import '../rider/rider_labels.dart';
import 'order_labels.dart';

final orderHistoryProvider = FutureProvider.autoDispose
    .family<List<Order>, AppMode>((ref, side) {
      final repo = ref.watch(ordersRepositoryProvider);
      return side == AppMode.rider ? repo.riderOrders() : repo.senderOrders();
    }, retry: (_, _) => null);

/// Past and current orders for one side, newest first.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key, required this.side});

  final AppMode side;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final orders = ref.watch(orderHistoryProvider(side));
    Widget body;
    if (orders.hasError && !orders.hasValue) {
      body = MessageView(
        key: const Key('history.error'),
        icon: Icons.wifi_off,
        title: l.historyLoadFailed,
        actionLabel: l.retryButton,
        actionKey: const Key('history.retry'),
        onAction: () => ref.invalidate(orderHistoryProvider(side)),
      );
    } else if (!orders.hasValue) {
      body = const LoadingView();
    } else if (orders.value!.isEmpty) {
      body = MessageView(
        key: const Key('history.empty'),
        icon: Icons.receipt_long_outlined,
        title: l.historyEmpty,
      );
    } else {
      final list = [...orders.value!]
        ..sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(orderHistoryProvider(side).future),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
          itemBuilder: (context, i) => HistoryRow(
            order: list[i],
            onTap: () => context.push(
              AppRoutes.orderDetailFor(
                list[i].id,
                asRider: side == AppMode.rider,
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      key: const Key('screen.history'),
      appBar: AppBar(
        title: Text(
          side == AppMode.rider ? l.historyRiderTitle : l.historyTitle,
        ),
      ),
      body: SafeArea(child: body),
    );
  }
}

class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final o = order;
    final created = o.createdAt;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: Key('history.order.${o.id}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSpacing.s10,
                  height: AppSpacing.s10,
                  decoration: BoxDecoration(
                    color: serviceTint(c, o.serviceType),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    serviceIcon(o.serviceType),
                    color: serviceAccent(c, o.serviceType),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.dropoffAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLg.copyWith(color: c.ink),
                      ),
                      Text(
                        l.historyFrom(o.pickupAddress),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Wrap(
                        spacing: AppSpacing.s2,
                        runSpacing: AppSpacing.s1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusChip(order: o),
                          if (created != null)
                            Text(
                              formatDateTime(l, created),
                              style: AppTextStyles.labelSm.copyWith(
                                color: c.inkFaint,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (o.agreedPrice != null) ...[
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    formatKes(o.agreedPrice!),
                    key: Key('history.price.${o.id}'),
                    style: AppTextStyles.mono.copyWith(color: c.ink),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
