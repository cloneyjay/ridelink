import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_messages.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/booking_labels.dart';
import '../booking/data/booking_models.dart';
import '../booking/widgets/booking_widgets.dart';
import '../common/confirm_dialog.dart';
import '../payments/late_report_card.dart';
import '../payments/payer_response_card.dart';
import '../payments/rider_settle_card.dart';
import '../restrictions/restriction_providers.dart';
import '../ratings/rating_sheet.dart';
import '../rider/rider_labels.dart';
import '../tracking/terms_sheet.dart';
import 'data/order_models.dart';
import 'order_labels.dart';
import 'order_providers.dart';

/// History detail: route, agreed price, the other party, terms, evidence record and rating.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.asRider = false,
  });

  final String orderId;

  /// Hint from the route when the order doesn't say who the sender is.
  final bool asRider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final details = ref.watch(orderDetailsProvider(orderId));
    Widget body;
    if (details.hasError && !details.hasValue) {
      body = MessageView(
        key: const Key('orderDetail.error'),
        icon: Icons.wifi_off,
        title: l.orderLoadFailed,
        actionLabel: l.retryButton,
        actionKey: const Key('orderDetail.retry'),
        onAction: () => ref.invalidate(orderDetailsProvider(orderId)),
      );
    } else if (!details.hasValue) {
      body = const LoadingView();
    } else {
      body = _DetailBody(details: details.value!, asRider: asRider);
    }
    return Scaffold(
      key: const Key('screen.orderDetail'),
      appBar: AppBar(title: Text(l.orderDetailTitle)),
      body: SafeArea(child: body),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.details, required this.asRider});

  final OrderDetails details;
  final bool asRider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final o = details.order;
    final userId = ref.watch(currentUserIdProvider);
    final role = o.senderId == null && details.senderName == null && asRider
        ? OrderRole.rider
        : roleFor(details, userId);
    final ride = o.serviceType == ServiceType.ride;
    final created = o.createdAt;
    final price = details.terms?.total ?? o.agreedPrice;
    final rider = details.rider;

    final otherParty = role == OrderRole.sender
        ? (rider == null
              ? null
              : (
                  label: l.detailRider,
                  name: rider.plateNumber.isEmpty
                      ? rider.displayName
                      : '${rider.displayName} · ${rider.plateNumber}',
                ))
        : (details.senderName == null
              ? null
              : (
                  label: ride ? l.detailPassenger : l.detailSender,
                  name: details.senderName!,
                ));

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(orderRatingsProvider(o.id));
        return ref.refresh(orderDetailsProvider(o.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPadding),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      serviceIcon(o.serviceType),
                      color: serviceAccent(c, o.serviceType),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Expanded(
                      child: Text(
                        serviceName(l, o.serviceType),
                        style: AppTextStyles.labelLg.copyWith(color: c.ink),
                      ),
                    ),
                    StatusChip(order: o),
                  ],
                ),
                if (created != null) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    formatDateTime(l, created),
                    style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                  ),
                ],
                if (price != null) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    l.agreedPrice,
                    style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                  ),
                  Text(
                    formatKes(price),
                    key: const Key('orderDetail.price'),
                    style: AppTextStyles.displaySm.copyWith(color: c.ink),
                  ),
                ],
                if (otherParty != null) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    otherParty.label,
                    style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                  ),
                  Text(
                    otherParty.name,
                    key: const Key('orderDetail.party'),
                    style: AppTextStyles.body.copyWith(color: c.ink),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          RouteSummary(
            pickup: o.pickupAddress,
            dropoff: o.dropoffAddress,
            trailing: o.distanceKm == null
                ? null
                : InfoChip(l.tripDistance(formatKm(o.distanceKm!))),
          ),
          if (o.status == 'unresolved' && role == OrderRole.sender) ...[
            const SizedBox(height: AppSpacing.s4),
            PayerResponseCard(
              key: const Key('orderDetail.payerResponse'),
              orderId: o.id,
              payer: o.payer,
            ),
          ],
          if (role == OrderRole.rider &&
              o.canReportLate(ref.read(serverNowProvider)())) ...[
            const SizedBox(height: AppSpacing.s4),
            _LateReport(orderId: o.id, deadline: o.lateReportUntil!),
          ],
          if (role == OrderRole.sender &&
              ref.watch(balanceForOrderProvider(o.id)) != null) ...[
            const SizedBox(height: AppSpacing.s4),
            _LinkTile(
              key: const Key('orderDetail.settleBalance'),
              icon: Icons.account_balance_wallet_outlined,
              label: l.settleBalanceTitle,
              onTap: () => context.push(AppRoutes.settleBalance),
            ),
          ],
          if (o.status == 'unresolved' && role == OrderRole.rider) ...[
            const SizedBox(height: AppSpacing.s4),
            NoteRow(
              l.paymentUnderReviewRiderBody,
              key: const Key('orderDetail.unresolvedRider'),
            ),
          ],
          if (role == OrderRole.rider &&
              (o.status == 'unresolved' ||
                  (o.status == 'closed_unpaid' && details.balanceOpen))) ...[
            const SizedBox(height: AppSpacing.s4),
            RiderSettleCard(
              keyPrefix: 'orderDetail.settle',
              orderId: o.id,
              body: o.status == 'unresolved' || price == null
                  ? l.riderSettleBodyUnresolved
                  : l.riderSettleBodyBalance(formatKes(price)),
              onConfirm: (method, code) async {
                await ref
                    .read(riderRepositoryProvider)
                    .paymentReceived(o.id, method: method, mpesaCode: code);
                ref.invalidate(orderDetailsProvider(o.id));
              },
              onForgive: details.balanceOpen
                  ? () async {
                      await ref
                          .read(restrictionsRepositoryProvider)
                          .forgiveBalance(o.id);
                      ref.invalidate(orderDetailsProvider(o.id));
                    }
                  : null,
            ),
          ],
          if (o.isActiveJob) ...[
            const SizedBox(height: AppSpacing.s4),
            PrimaryButton(
              key: const Key('orderDetail.openLive'),
              label: l.openLiveOrder,
              onPressed: () => context.go(
                role == OrderRole.sender
                    ? AppRoutes.trackingFor(o.id)
                    : AppRoutes.riderHome,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s4),
          if (details.terms != null || o.agreedPrice != null)
            _LinkTile(
              key: const Key('orderDetail.terms'),
              icon: Icons.description_outlined,
              label: l.viewTerms,
              onTap: () =>
                  showTermsSheet(context, order: o, terms: details.terms),
            ),
          if (o.acceptedAt != null || o.riderId != null)
            _LinkTile(
              key: const Key('orderDetail.evidence'),
              icon: Icons.verified_user_outlined,
              label: l.evidenceTitle,
              onTap: () => context.push(AppRoutes.evidenceFor(o.id)),
            ),
          if (o.status == 'completed') ...[
            const SizedBox(height: AppSpacing.s4),
            _RatingSection(order: o, role: role),
          ],
        ],
      ),
    );
  }
}

/// Rider "Not paid" on a timeout-closed order; the reloaded order then shows `unresolved`.
class _LateReport extends ConsumerStatefulWidget {
  const _LateReport({required this.orderId, required this.deadline});

  final String orderId;
  final DateTime deadline;

  @override
  ConsumerState<_LateReport> createState() => _LateReportState();
}

class _LateReportState extends ConsumerState<_LateReport> {
  bool _busy = false;

  Future<void> _report() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(riderRepositoryProvider)
          .paymentNotReceived(widget.orderId);
    } catch (e) {
      if (mounted) {
        showSnack(
          context,
          apiErrorText(e, l, fallback: l.jobActionFailed),
          key: const Key('orderDetail.lateReportError'),
        );
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(orderDetailsProvider(widget.orderId));
  }

  @override
  Widget build(BuildContext context) => LateReportCard(
    keyPrefix: 'orderDetail.late',
    deadline: widget.deadline,
    busy: _busy,
    onReport: _report,
  );
}

class _RatingSection extends ConsumerWidget {
  const _RatingSection({required this.order, required this.role});

  final Order order;
  final OrderRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final userId = ref.watch(currentUserIdProvider);
    final ratings = ref.watch(orderRatingsProvider(order.id));
    if (!ratings.hasValue) {
      return ratings.hasError ? const SizedBox.shrink() : const LoadingView();
    }
    final mine = ratings.value!.where((r) => r.fromId == userId).firstOrNull;
    return SurfaceCard(
      key: const Key('orderDetail.rating'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.yourRating,
            style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s1),
          if (mine != null) ...[
            StarRow(key: const Key('orderDetail.myScore'), score: mine.score),
            if (mine.comment != null && mine.comment!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s1),
              Text(
                mine.comment!,
                style: AppTextStyles.body.copyWith(color: c.ink),
              ),
            ],
          ] else ...[
            Text(
              l.notRatedYet,
              style: AppTextStyles.body.copyWith(color: c.ink),
            ),
            const SizedBox(height: AppSpacing.s2),
            OutlinedButton(
              key: const Key('orderDetail.rate'),
              onPressed: () => showRatingSheet(
                context,
                orderId: order.id,
                target: ratingTargetFor(role, order.serviceType),
              ),
              child: Text(l.rateButton),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          child: Row(
            children: [
              Icon(icon, color: c.inkMuted),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
              ),
              Icon(Icons.chevron_right, color: c.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
