import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/geo_point.dart';
import '../../core/map/map_config.dart';
import '../../core/map/ridelink_map.dart';
import '../../core/mode/app_mode.dart';
import '../../core/location/location_service.dart';
import '../../core/providers.dart';
import '../../core/realtime/realtime_event.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../booking/booking_labels.dart';
import '../booking/resume.dart';
import '../push/notification_prompt.dart';
import '../booking/data/booking_models.dart';
import '../notifications/notifications_screen.dart';
import '../restrictions/balance_widgets.dart';
import '../restrictions/restriction_providers.dart';
import '../rider/rider_controller.dart';
import '../rider/widgets/rider_offer_watcher.dart';
import '../shell/app_menu.dart';

/// Screen 2: map with the sender's location and a sheet to start a delivery or ride.
class SenderHomeScreen extends ConsumerStatefulWidget {
  const SenderHomeScreen({super.key});

  @override
  ConsumerState<SenderHomeScreen> createState() => _SenderHomeScreenState();
}

class _SenderHomeScreenState extends ConsumerState<SenderHomeScreen>
    with WidgetsBindingObserver {
  LocationResult? _location;
  List<ResumeTarget> _active = const [];
  bool _resuming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // One system prompt at a time: location first, then notifications.
    unawaited(_load(prompt: true).then((_) => _askNotifications()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appModeProvider).set(AppMode.sender);
      unawaited(_resume());
      unawaited(_resumeRiderSide());
    });
  }

  /// The server is the only source of live order state: on start, foreground and realtime
  /// reconnect, GET /orders/active decides where the sender belongs. Home only redirects
  /// while it is the visible screen, and never back to a live screen opened this session.
  Future<void> _resume() async {
    if (_resuming) return;
    _resuming = true;
    ref.invalidate(outstandingBalancesProvider);
    ref.invalidate(accountStatusProvider);
    try {
      final orders = await ref.read(bookingRepositoryProvider).activeOrders();
      if (!mounted) return;
      final targets = resumeTargets(orders);
      setState(() => _active = targets);
      if (targets.isEmpty) return;
      final target = targets.first;
      final opened = ref.read(sessionFlagsProvider).openedLiveScreens;
      final visible = ModalRoute.of(context)?.isCurrent ?? false;
      if (!visible || opened.contains(target.key)) return;
      opened.add(target.key);
      context.go(target.location, extra: target.extra);
    } catch (_) {
      // Offline: the next foreground or reconnect tries again.
    } finally {
      _resuming = false;
    }
  }

  Future<void> _askNotifications() async {
    var rider = false;
    try {
      rider = await ref.read(isRiderProvider.future);
    } catch (_) {}
    if (!mounted) return;
    await maybeAskNotificationPermission(context, ref, explain: rider);
  }

  /// A rider who is online server-side keeps sharing location while in sender mode (e.g. the
  /// app restarted on this side): starting the rider controller resumes tracking.
  Future<void> _resumeRiderSide() async {
    try {
      final isRider = await ref.read(isRiderProvider.future);
      if (isRider && mounted) ref.read(riderControllerProvider);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_resume());
    // Back from system settings: pick up a newly granted permission or enabled GPS.
    if (_location is! LocationFound) unawaited(_load(prompt: false));
  }

  Future<void> _load({required bool prompt}) async {
    final service = ref.read(locationServiceProvider);
    final result = prompt
        ? await service.requestAndGet()
        : await service.current();
    if (!mounted) return;
    setState(() => _location = result);
    if (result is LocationFound) {
      ref
          .read(lastKnownLocationProvider.notifier)
          .set(
            LocationFix(
              point: result.point,
              accuracyM: result.accuracyM,
              at: ref.read(clockProvider)(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (_, next) {
      if (next.value?.kind == RealtimeEventKind.connected) unawaited(_resume());
    });
    final location = _location;
    return RiderOfferWatcher(
      child: Scaffold(
        key: const Key('screen.home'),
        drawer: const AppMenuDrawer(side: AppSide.sender),
        body: Stack(
          children: [
            Positioned.fill(
              child: _MapArea(
                point: location is LocationFound ? location.point : null,
              ),
            ),
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppLayout.screenPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [MenuButton(), NotificationBell(floating: true)],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _HomeSheet(
                location: location,
                active: _active,
                onAllow: () => _load(prompt: true),
                onRetry: () => _load(prompt: false),
                onOpenAppSettings: () =>
                    ref.read(locationServiceProvider).openAppSettings(),
                onOpenLocationSettings: () =>
                    ref.read(locationServiceProvider).openLocationSettings(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapArea extends StatefulWidget {
  const _MapArea({required this.point});

  final GeoPoint? point;

  @override
  State<_MapArea> createState() => _MapAreaState();
}

class _MapAreaState extends State<_MapArea> {
  RideLinkMapController? _controller;

  @override
  void didUpdateWidget(_MapArea old) {
    super.didUpdateWidget(old);
    final p = widget.point;
    if (p != null && p != old.point) {
      unawaited(_controller?.moveTo(p, zoom: 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.point;
    final top = MediaQuery.paddingOf(context).top;
    return RideLinkMap(
      key: const Key('home.map'),
      initialCenter: p ?? MapConfig.fallbackCenter,
      initialZoom: p == null ? 12 : 15,
      showMyLocation: p != null,
      onCreated: (c) => _controller = c,
      // Below the menu and bell row; the bottom sheet covers the map's lower edge.
      attributionAlignment: AlignmentDirectional.topEnd,
      attributionPadding: EdgeInsets.only(
        top: top + AppLayout.screenPadding + AppLayout.minTapTarget,
        right: AppLayout.screenPadding - AppSpacing.s1,
        left: AppLayout.screenPadding - AppSpacing.s1,
      ),
    );
  }
}

class _HomeSheet extends StatelessWidget {
  const _HomeSheet({
    required this.location,
    required this.active,
    required this.onAllow,
    required this.onRetry,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
  });

  final LocationResult? location;
  final List<ResumeTarget> active;
  final VoidCallback onAllow;
  final VoidCallback onRetry;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Container(
      key: const Key('home.sheet'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppLayout.sheetTopRadius),
        ),
        boxShadow: context.shadows.lg,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.screenPadding,
            AppSpacing.s3,
            AppLayout.screenPadding,
            AppSpacing.s4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: AppSpacing.s10,
                  height: AppSpacing.s1,
                  decoration: BoxDecoration(
                    color: c.borderStrong,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              if (active.isNotEmpty) ...[
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      key: const Key('home.activeOrders'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, t) in active.indexed) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.s2),
                          _ActiveOrderCard(target: t),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
              ],
              const HomeRestrictionBanners(),
              if (_locationCard(context) case final card?) ...[
                card,
                const SizedBox(height: AppSpacing.s4),
              ],
              Text(
                l.homeWhatDoYouNeed,
                style: AppTextStyles.displaySm.copyWith(color: c.ink),
              ),
              const SizedBox(height: AppSpacing.s3),
              const Row(
                children: [
                  Expanded(child: _ServiceTile(service: ServiceType.delivery)),
                  SizedBox(width: AppSpacing.s3),
                  Expanded(child: _ServiceTile(service: ServiceType.ride)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _locationCard(BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (location) {
      null || LocationFound() => null,
      LocationDenied() => _LocationCard(
        key: const Key('home.location.denied'),
        body: l.locationDeniedBody,
        action: l.locationAllow,
        onAction: onAllow,
      ),
      LocationDeniedForever() => _LocationCard(
        key: const Key('home.location.deniedForever'),
        body: l.locationDeniedBody,
        action: l.locationOpenSettings,
        onAction: onOpenAppSettings,
      ),
      LocationServiceOff() => _LocationCard(
        key: const Key('home.location.serviceOff'),
        body: l.locationServiceOffBody,
        action: l.locationTurnOn,
        onAction: onOpenLocationSettings,
      ),
      LocationUnavailable() => _LocationCard(
        key: const Key('home.location.unavailable'),
        body: l.locationUnavailableBody,
        action: l.retryButton,
        onAction: onRetry,
      ),
    };
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    super.key,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, color: c.statusWarning),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.locationDeniedTitle,
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  body,
                  style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          TextButton(
            key: const Key('home.location.action'),
            onPressed: onAction,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends ConsumerWidget {
  const _ServiceTile({required this.service});

  final ServiceType service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    // Suspended senders can't book (D6); the banner above explains why.
    final suspended = ref.watch(isSuspendedProvider);
    final accent = suspended ? c.inkFaint : serviceAccent(c, service);
    return Material(
      color: suspended ? c.surfaceSunken : serviceTint(c, service),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        key: Key('home.service.${service.wire}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: suspended
            ? null
            : () => context.push(AppRoutes.newOrderFor(service)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(serviceIcon(service), color: accent, size: AppSpacing.s8),
              const SizedBox(height: AppSpacing.s2),
              Text(
                serviceName(l, service),
                style: AppTextStyles.labelLg.copyWith(color: c.ink),
              ),
              Text(
                service == ServiceType.delivery
                    ? l.serviceDeliverySubtitle
                    : l.serviceRideSubtitle,
                style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One live order (waiting on a rider, or in progress); every active order stays reachable.
class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.target});

  final ResumeTarget target;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final t = target;
    final order = switch (t) {
      ResumeWaiting() => t.pending.order,
      ResumeTracking() => t.order,
    };
    final title = switch (t) {
      ResumeWaiting() => l.waitingTitle(t.pending.rider.displayName),
      ResumeTracking() => l.activeOrderBanner,
    };
    return Material(
      color: serviceTint(c, order.serviceType),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        key: Key('home.activeOrder.${order.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          context.go(t.location, extra: t.extra);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Row(
              children: [
                Icon(
                  serviceIcon(order.serviceType),
                  color: serviceAccent(c, order.serviceType),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelLg.copyWith(color: c.ink),
                      ),
                      if (order.dropoffAddress.isNotEmpty)
                        Text(
                          order.dropoffAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm.copyWith(
                            color: c.inkMuted,
                          ),
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
