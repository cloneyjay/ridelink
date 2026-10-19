import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/errors/error_messages.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../common/confirm_dialog.dart';
import 'booking_routes.dart';
import 'data/booking_models.dart';
import 'resume.dart';
import 'widgets/booking_widgets.dart';

enum RiderSort { price, distance }

/// Cheapest (or closest) first; the other key breaks ties.
List<RiderQuote> sortRiders(List<RiderQuote> riders, RiderSort sort) {
  int byPrice(RiderQuote a, RiderQuote b) => a.total.compareTo(b.total);
  int byDistance(RiderQuote a, RiderQuote b) =>
      a.pickupDistanceKm.compareTo(b.pickupDistanceKm);
  final sorted = [...riders];
  sorted.sort(
    (a, b) => switch (sort) {
      RiderSort.price => byPrice(a, b) != 0 ? byPrice(a, b) : byDistance(a, b),
      RiderSort.distance =>
        byDistance(a, b) != 0 ? byDistance(a, b) : byPrice(a, b),
    },
  );
  return sorted;
}

/// Riders for a created order with their total price and arrival window (decision 7).
class RiderListScreen extends ConsumerStatefulWidget {
  const RiderListScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
    this.notice,
  });

  final String orderId;
  final Order? initialOrder;
  final RiderListNotice? notice;

  @override
  ConsumerState<RiderListScreen> createState() => _RiderListScreenState();
}

class _RiderListScreenState extends ConsumerState<RiderListScreen> {
  Order? _order;
  RiderList? _list;
  bool _loading = true;
  bool _failed = false;
  RiderSort _sort = RiderSort.price;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _load();
    _showNotice(widget.notice);
  }

  @override
  void didUpdateWidget(RiderListScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialOrder != null &&
        widget.initialOrder != old.initialOrder) {
      _order = widget.initialOrder;
    }
    if (widget.notice != old.notice ||
        widget.initialOrder != old.initialOrder) {
      _showNotice(widget.notice);
      _load();
    }
  }

  void _showNotice(RiderListNotice? notice) {
    if (notice == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('riders.notice'),
            content: Text(switch (notice) {
              RiderListNotice.offerDeclined => l.offerDeclinedMessage,
              RiderListNotice.offerExpired => l.offerExpiredMessage,
            }),
          ),
        );
    });
  }

  Future<void> _load() async {
    if (!_loading || _failed) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    final repo = ref.read(bookingRepositoryProvider);
    try {
      final order = _order ?? await repo.getOrder(widget.orderId);
      final list = await repo.ridersForOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _list = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _editRoute() async {
    final order = _order;
    if (order == null) return;
    final updated = await context.push<Order>(
      AppRoutes.editRouteFor(order.id),
      extra: order,
    );
    if (updated == null || !mounted) return;
    _order = updated;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final order = _order;
    final list = _list;
    final distance = list?.tripDistanceKm ?? order?.distanceKm;
    final estimated =
        (list?.distanceEstimated ?? false) ||
        (list == null && (order?.distanceEstimated ?? false));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        key: const Key('screen.riderList'),
        appBar: AppBar(title: Text(l.riderListTitle)),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (order != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.screenPadding,
                    AppSpacing.s3,
                    AppLayout.screenPadding,
                    0,
                  ),
                  child: RouteSummary(
                    pickup: order.pickupAddress,
                    dropoff: order.dropoffAddress,
                    trailing: Row(
                      children: [
                        if (distance != null)
                          InfoChip(
                            l.tripDistance(formatKm(distance)),
                            key: const Key('riders.tripDistance'),
                          ),
                        const Spacer(),
                        if (order.routeEditable)
                          TextButton.icon(
                            key: const Key('riders.editRoute'),
                            onPressed: _editRoute,
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l.editRoute),
                          ),
                      ],
                    ),
                  ),
                ),
              if (estimated)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.screenPadding,
                    AppSpacing.s2,
                    AppLayout.screenPadding,
                    0,
                  ),
                  child: NoteRow(
                    l.distanceEstimatedNote,
                    key: const Key('riders.estimatedNote'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.screenPadding,
                  vertical: AppSpacing.s3,
                ),
                child: SegmentedButton<RiderSort>(
                  key: const Key('riders.sort'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: RiderSort.price,
                      label: Text(
                        l.sortByPrice,
                        key: const Key('riders.sort.price'),
                      ),
                      icon: const Icon(Icons.payments_outlined),
                    ),
                    ButtonSegment(
                      value: RiderSort.distance,
                      label: Text(
                        l.sortByDistance,
                        key: const Key('riders.sort.distance'),
                      ),
                      icon: const Icon(Icons.near_me_outlined),
                    ),
                  ],
                  selected: {_sort},
                  onSelectionChanged: (s) => setState(() => _sort = s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: c.brand100,
                    selectedForegroundColor: c.brand700,
                    textStyle: AppTextStyles.label,
                    minimumSize: const Size(0, AppLayout.minTapTarget),
                  ),
                ),
              ),
              Expanded(child: _body(l)),
            ],
          ),
        ),
      ),
    );
  }

  bool _discarding = false;

  /// Leaving the list discards the order (frontend decision 11), after a confirm.
  Future<void> _confirmDiscard() async {
    if (_discarding) return;
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      keyPrefix: 'riders.discardDialog',
      title: l.discardOrderTitle,
      body: l.discardOrderBody,
      confirmLabel: l.discardOrderConfirm,
      cancelLabel: l.discardOrderKeep,
    );
    if (!ok || !mounted) return;
    _discarding = true;
    try {
      await ref.read(bookingRepositoryProvider).cancelOrder(widget.orderId);
      if (!mounted) return;
      context.go(AppRoutes.home);
    } on ApiException catch (e) {
      _discarding = false;
      if (!mounted) return;
      if (!e.isConflict) {
        showSnack(
          context,
          l.discardOrderFailed,
          key: const Key('riders.discardFailed'),
        );
        return;
      }
      showSnack(context, conflictText(e, l), key: const Key('riders.conflict'));
      try {
        final view = await ref
            .read(bookingRepositoryProvider)
            .senderOrder(widget.orderId);
        if (!mounted) return;
        final route = senderRouteAfterConflict(view);
        context.go(route.location, extra: route.extra);
      } catch (_) {}
    } catch (_) {
      _discarding = false;
      if (!mounted) return;
      showSnack(
        context,
        l.discardOrderFailed,
        key: const Key('riders.discardFailed'),
      );
    }
  }

  Widget _body(AppLocalizations l) {
    if (_loading) return const LoadingView();
    if (_failed) {
      return MessageView(
        key: const Key('riders.error'),
        icon: Icons.wifi_off,
        title: l.ridersLoadFailed,
        actionLabel: l.retryButton,
        actionKey: const Key('riders.retry'),
        onAction: _load,
      );
    }
    final riders = sortRiders(_list?.riders ?? const [], _sort);
    if (riders.isEmpty) {
      return MessageView(
        key: const Key('riders.empty'),
        icon: Symbols.two_wheeler,
        title: l.noRidersTitle,
        body: l.noRidersBody,
        actionLabel: l.retryButton,
        actionKey: const Key('riders.retry'),
        onAction: _load,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.screenPadding,
          0,
          AppLayout.screenPadding,
          AppSpacing.s6,
        ),
        itemCount: riders.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
        itemBuilder: (context, i) => RiderRow(
          rider: riders[i],
          onTap: () => context.push(
            AppRoutes.riderProfileFor(widget.orderId),
            extra: RiderChoice(order: _order!, rider: riders[i]),
          ),
        ),
      ),
    );
  }
}

class RiderRow extends StatelessWidget {
  const RiderRow({super.key, required this.rider, required this.onTap});

  final RiderQuote rider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final muted = AppTextStyles.bodySm.copyWith(color: c.inkMuted);
    final facts = <String>[
      if (rider.onTimeRate != null)
        l.onTimePercent((rider.onTimeRate! * 100).round()),
      if (rider.completed != null) l.completedJobs(rider.completed!),
    ];
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: Key('riders.row.${rider.riderId}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RiderAvatar(
                riderId: rider.riderId,
                name: rider.displayName,
                hasPhoto: rider.hasPhoto,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.displayName,
                      style: AppTextStyles.labelLg.copyWith(color: c.ink),
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    RatingLine(rider: rider),
                    if (facts.isNotEmpty) Text(facts.join(' · '), style: muted),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      '${l.pickupDistanceAway(formatKm(rider.pickupDistanceKm))} · '
                      '${l.arrivesWithin(rider.pickupWindowMins)}',
                      style: muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                formatKes(rider.total),
                key: Key('riders.price.${rider.riderId}'),
                style: AppTextStyles.displaySm.copyWith(color: c.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RatingLine extends StatelessWidget {
  const RatingLine({super.key, required this.rider});

  final RiderQuote rider;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (rider.ratingCount == 0) {
      return Text(
        l.noRatingsYet,
        style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
      );
    }
    return Row(
      children: [
        Icon(Icons.star, size: AppSpacing.s4, color: c.brand300),
        const SizedBox(width: AppSpacing.s1),
        Text(
          rider.ratingAverage.toStringAsFixed(1),
          style: AppTextStyles.label.copyWith(color: c.ink),
        ),
        const SizedBox(width: AppSpacing.s1),
        Text(
          '(${l.ratingCount(rider.ratingCount)})',
          style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}
