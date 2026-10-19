import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../core/api/api_exception.dart';
import '../../core/errors/error_messages.dart';
import '../../core/format/money.dart';
import '../../core/location/geo_point.dart';
import '../../core/providers.dart';
import '../../core/realtime/realtime_event.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../booking/data/booking_models.dart';
import '../booking/resume.dart' show trackingScreenKey;
import '../booking/widgets/booking_widgets.dart';
import '../common/confirm_dialog.dart';
import '../evidence/data/evidence_models.dart';
import '../evidence/photo_evidence_card.dart';
import '../home/sender_home_screen.dart' show MapPlaceholder;
import '../notifications/notifications_screen.dart';
import '../orders/data/order_models.dart';
import '../orders/order_providers.dart';
import '../ratings/rating_sheet.dart';
import '../rider/job/job_logic.dart';
import 'terms_sheet.dart';

/// What the sender already knows when arriving from the waiting screen.
class TrackingArgs {
  const TrackingArgs({
    this.order,
    this.riderId,
    this.riderName,
    this.riderHasPhoto = false,
    this.breakdown,
  });

  final Order? order;
  final String? riderId;
  final String? riderName;
  final bool riderHasPhoto;
  final QuoteBreakdown? breakdown;
}

/// Screen 7 (sender): live rider position, one pickup countdown (decision 7), step progress,
/// and the cash payment step (pricing decision 18).
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key, required this.orderId, this.args});

  final String orderId;
  final TrackingArgs? args;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with WidgetsBindingObserver {
  Order? _order;
  OrderDetails? _details;
  GeoPoint? _rider;
  bool _loadFailed = false;
  bool _busy = false;
  bool _sharing = false;
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _order = widget.args?.order;
    ref
        .read(sessionFlagsProvider)
        .openedLiveScreens
        .add(trackingScreenKey(widget.orderId));
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final o = _order;
      if (mounted && o != null && pickupCountdown(o, _now) != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  DateTime get _now => ref.read(serverNowProvider)();

  /// GET /orders/{id} with the rider and agreed terms, so the screen works after a restart.
  Future<void> _load() async {
    try {
      final details = await ref
          .read(ordersRepositoryProvider)
          .details(widget.orderId);
      if (!mounted) return;
      setState(() {
        _details = details;
        _order = details.order;
        _loadFailed = false;
      });
      _afterChange();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = _order == null);
    }
  }

  void _setOrder(Order order) {
    setState(() => _order = order);
    _afterChange();
  }

  /// Completion asks the sender to rate the rider, once.
  void _afterChange() {
    final order = _order;
    if (order == null || order.status != 'completed') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybePromptRating(context, ref, order: order, role: OrderRole.sender);
      }
    });
  }

  Future<void> _shareWithReceiver() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _sharing = true;
      _error = null;
    });
    try {
      final link = await ref
          .read(ordersRepositoryProvider)
          .createReceiverLink(widget.orderId);
      await ref
          .read(shareServiceProvider)
          .shareText(l.receiverShareMessage(link.url));
      if (mounted) setState(() => _sharing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sharing = false;
        _error = apiErrorText(e, l, fallback: l.receiverLinkFailed);
      });
    }
  }

  void _onEvent(RealtimeEvent event) {
    final data = event.data;
    if (data['order_id'] != widget.orderId) return;
    switch (event.kind) {
      case RealtimeEventKind.orderUpdated:
        final order = _order;
        if (order == null) {
          _load();
          return;
        }
        _setOrder(order.applyUpdate(data));
      case RealtimeEventKind.riderLocation:
        final lat = data['lat'], lng = data['lng'];
        if (lat is num && lng is num) {
          setState(() => _rider = GeoPoint(lat.toDouble(), lng.toDouble()));
        }
      default:
        return;
    }
  }

  Future<void> _run(Future<Order> Function() call) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await call();
      if (!mounted) return;
      setState(() => _busy = false);
      _setOrder(order);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        setState(() => _busy = false);
        showSnack(
          context,
          conflictText(e, l),
          key: const Key('tracking.conflict'),
        );
        await _load();
        return;
      }
      setState(() {
        _busy = false;
        _error = apiErrorText(e, l, fallback: l.trackingActionFailed);
      });
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l.trackingActionFailed;
      });
    }
  }

  Future<void> _paid() async {
    final l = AppLocalizations.of(context);
    final amount = formatKes(_order?.agreedPrice ?? 0);
    final ok = await confirmDialog(
      context,
      keyPrefix: 'tracking.paidDialog',
      title: l.ivePaidConfirmTitle(amount),
      body: l.ivePaidConfirmBody,
      confirmLabel: l.ivePaidButton,
      cancelLabel: l.goBackButton,
    );
    if (!ok || !mounted) return;
    await _run(
      () => ref
          .read(bookingRepositoryProvider)
          .confirmPaymentSent(widget.orderId),
    );
  }

  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      keyPrefix: 'tracking.cancelDialog',
      title: l.senderCancelTitle,
      body: l.senderCancelBody,
      confirmLabel: l.cancelConfirmYes,
      cancelLabel: l.senderCancelKeep,
    );
    if (!ok || !mounted) return;
    await _run(
      () => ref.read(bookingRepositoryProvider).cancelOrder(widget.orderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (_, next) {
      final event = next.value;
      if (event != null) _onEvent(event);
    });
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final order = _order;

    return Scaffold(
      key: const Key('screen.tracking'),
      appBar: AppBar(
        leading: BackButton(
          key: const Key('tracking.back'),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Text(l.trackingScreenTitle),
        actions: const [NotificationBell()],
      ),
      body: order == null
          ? (_loadFailed
                ? MessageView(
                    key: const Key('tracking.error'),
                    icon: Icons.wifi_off,
                    title: l.trackingLoadFailed,
                    actionLabel: l.retryButton,
                    actionKey: const Key('tracking.retry'),
                    onAction: _load,
                  )
                : const LoadingView())
          : Column(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.32,
                  child: _TrackingMap(order: order, rider: _rider),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.surfaceRaised,
                      boxShadow: context.shadows.lg,
                    ),
                    child: SafeArea(
                      top: false,
                      child: ListView(
                        padding: const EdgeInsets.all(AppLayout.screenPadding),
                        children: _sheet(l, c, order),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _sheet(AppLocalizations l, AppColors c, Order o) {
    final args = widget.args;
    final details = _details;
    final rider = details?.rider;
    final riderId = rider?.riderId ?? args?.riderId;
    final riderName = rider?.displayName ?? args?.riderName;
    final hasPhoto = rider?.hasPhoto ?? args?.riderHasPhoto ?? false;
    final countdown = pickupCountdown(o, _now);
    final amount = formatKes(o.agreedPrice ?? details?.terms?.total ?? 0);
    final banner = _banner(l, c, o, countdown);
    final isDelivery = o.serviceType == ServiceType.delivery;
    return [
      if (riderName != null) ...[
        Row(
          children: [
            RiderAvatar(
              riderId: riderId ?? '',
              name: riderName,
              hasPhoto: hasPhoto && riderId != null,
              size: AppSpacing.s10,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    riderName,
                    key: const Key('tracking.riderName'),
                    style: AppTextStyles.labelLg.copyWith(color: c.ink),
                  ),
                  if (rider != null && rider.plateNumber.isNotEmpty)
                    Text(
                      rider.plateNumber,
                      key: const Key('tracking.plate'),
                      style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                    ),
                ],
              ),
            ),
            if (o.agreedPrice != null)
              Text(
                amount,
                style: AppTextStyles.displaySm.copyWith(color: c.ink),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
      ],
      ?banner,
      if (banner != null) const SizedBox(height: AppSpacing.s4),
      if (o.status != 'cancelled') ...[
        StepProgress(current: trackingStep(o), order: o),
        const SizedBox(height: AppSpacing.s4),
      ],
      ..._paymentSection(l, c, o, amount),
      if (isDelivery && o.status == 'accepted') ...[
        PhotoEvidenceCard(
          orderId: o.id,
          kind: MediaKind.itemPhoto,
          hint: l.evidenceItemPhotoHint,
          optional: true,
        ),
        const SizedBox(height: AppSpacing.s3),
      ],
      if (isDelivery && !o.isTerminal) ...[
        OutlinedButton.icon(
          key: const Key('tracking.shareReceiver'),
          onPressed: _sharing ? null : _shareWithReceiver,
          icon: _sharing
              ? SizedBox.square(
                  dimension: AppSpacing.s4,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.brand500,
                  ),
                )
              : const Icon(Icons.share_outlined),
          label: Text(l.shareWithReceiver),
        ),
        const SizedBox(height: AppSpacing.s1),
        NoteRow(l.shareWithReceiverNote),
      ],
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.s3),
        InlineError(_error!, key: const Key('tracking.actionError')),
      ],
      const SizedBox(height: AppSpacing.s3),
      Wrap(
        spacing: AppSpacing.s2,
        children: [
          TextButton.icon(
            key: const Key('tracking.viewTerms'),
            onPressed: () => showTermsSheet(
              context,
              order: o,
              terms: details?.terms,
              breakdown: args?.breakdown,
            ),
            icon: const Icon(Icons.description_outlined),
            label: Text(l.viewTerms),
          ),
          TextButton.icon(
            key: const Key('tracking.evidence'),
            onPressed: () => context.push(AppRoutes.evidenceFor(o.id)),
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(l.evidenceTitle),
          ),
        ],
      ),
      if (o.status == 'accepted')
        OutlinedButton(
          key: const Key('tracking.cancel'),
          onPressed: _busy ? null : _cancel,
          child: Text(l.senderCancelButton),
        ),
      if (o.isTerminal) ...[
        const SizedBox(height: AppSpacing.s3),
        PrimaryButton(
          key: const Key('tracking.home'),
          label: l.backToHome,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ],
    ];
  }

  Widget? _banner(
    AppLocalizations l,
    AppColors c,
    Order o,
    Duration? countdown,
  ) {
    final (String key, String text, IconData icon, Color color)? spec =
        switch (o.status) {
          'accepted' when countdown == Duration.zero => (
            'tracking.late',
            l.riderRunningLate,
            Icons.schedule,
            c.statusWarning,
          ),
          'accepted' when countdown != null => (
            'tracking.countdown',
            l.riderArrivesIn(math.max(1, minutesLeft(countdown))),
            Icons.schedule,
            c.ink,
          ),
          'accepted' when o.arrivedAtPickup => (
            'tracking.arrived',
            l.riderArrivedAtPickup,
            Icons.where_to_vote,
            c.statusSuccess,
          ),
          'started' || 'in_transit' => (
            'tracking.inTransit',
            l.trackingOnTheWay,
            Icons.navigation,
            c.ink,
          ),
          'arrived' => (
            'tracking.atDropoff',
            l.riderAtDropoff,
            Icons.where_to_vote,
            c.statusSuccess,
          ),
          'handed_over' || 'completed' => (
            'tracking.done',
            o.serviceType == ServiceType.ride ? l.tripComplete : l.delivered,
            Icons.check_circle,
            c.statusSuccess,
          ),
          'cancelled' => (
            'tracking.cancelled',
            switch (o.cancelReason) {
              'pickup_timeout' => l.orderCancelledTimeout,
              'rider' => l.orderCancelledByRider,
              'sender' => l.orderCancelledBySender,
              _ => l.orderCancelledMessage,
            },
            Icons.cancel,
            c.statusError,
          ),
          _ => null,
        };
    if (spec == null) return null;
    final (key, text, icon, color) = spec;
    return Row(
      children: [
        Icon(icon, color: color, size: AppSpacing.s8),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Text(
            text,
            key: Key(key),
            style: AppTextStyles.displaySm.copyWith(color: c.ink),
          ),
        ),
      ],
    );
  }

  List<Widget> _paymentSection(
    AppLocalizations l,
    AppColors c,
    Order o,
    String amount,
  ) {
    Widget card(
      String key,
      String title,
      String? body, {
      Widget? action,
    }) => Container(
      key: Key(key),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: key == 'tracking.unresolved'
            ? c.statusErrorTint
            : c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.displaySm.copyWith(color: c.ink)),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(body, style: AppTextStyles.body.copyWith(color: c.inkMuted)),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.s4),
            action,
          ],
        ],
      ),
    );
    return switch (o.status) {
      'payment_requested' => [
        card(
          'tracking.payNow',
          l.payInCash(amount),
          l.payInCashBody,
          action: PrimaryButton(
            key: const Key('tracking.ivePaid'),
            label: l.ivePaidButton,
            loading: _busy,
            onPressed: _paid,
          ),
        ),
      ],
      'cash_pending' => [
        card('tracking.waitingRider', l.waitingForRiderConfirm, null),
      ],
      'paid' => [card('tracking.paid', l.paymentConfirmed(amount), null)],
      'unresolved' => [
        card(
          'tracking.unresolved',
          l.paymentUnderReview,
          l.paymentUnderReviewSenderBody,
        ),
      ],
      _ => const [],
    };
  }
}

/// accepted -> at pickup -> in transit -> payment -> delivered.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current, required this.order});

  final TrackingStep current;
  final Order order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final finished =
        order.status == 'completed' || order.status == 'handed_over';
    String label(TrackingStep s) => switch (s) {
      TrackingStep.accepted => l.stepAccepted,
      TrackingStep.atPickup => l.stepAtPickup,
      TrackingStep.inTransit => l.stepInTransit,
      TrackingStep.payment => l.stepPayment,
      TrackingStep.delivered =>
        order.serviceType == ServiceType.ride
            ? l.stepDroppedOff
            : l.stepDelivered,
    };
    return Column(
      children: [
        for (final s in TrackingStep.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
            child: Row(
              children: [
                Icon(
                  s.index < current.index || finished
                      ? Icons.check_circle
                      : s == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: AppSpacing.s5,
                  color: s.index < current.index || finished
                      ? c.statusSuccess
                      : s == current
                      ? c.brand500
                      : c.inkFaint,
                ),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  label(s),
                  key: Key(
                    'tracking.step.${s.name}${s == current ? '.current' : ''}',
                  ),
                  style:
                      (s == current
                              ? AppTextStyles.labelLg
                              : AppTextStyles.body)
                          .copyWith(
                            color: s.index <= current.index
                                ? c.ink
                                : c.inkMuted,
                          ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TrackingMap extends ConsumerWidget {
  const _TrackingMap({required this.order, required this.rider});

  final Order order;
  final GeoPoint? rider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasKey = ref.watch(hasMapsKeyProvider).value ?? false;
    if (!hasKey) return const MapPlaceholder();
    gmaps.LatLng ll(GeoPoint p) => gmaps.LatLng(p.lat, p.lng);
    final pickup = order.pickupLocation;
    final dropoff = order.dropoffLocation;
    final center = rider ?? pickup ?? dropoff;
    return gmaps.GoogleMap(
      key: const Key('tracking.map'),
      initialCameraPosition: gmaps.CameraPosition(
        target: center == null
            ? const gmaps.LatLng(-1.2864, 36.8172)
            : ll(center),
        zoom: 14,
      ),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: {
        if (pickup != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('pickup'),
            position: ll(pickup),
          ),
        if (dropoff != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('dropoff'),
            position: ll(dropoff),
          ),
        if (rider != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('rider'),
            position: ll(rider!),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueAzure,
            ),
          ),
      },
    );
  }
}
