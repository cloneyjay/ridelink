import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/realtime/realtime_event.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../tracking/tracking_screen.dart';
import 'booking_routes.dart';
import 'rider_profile_screen.dart';
import 'widgets/booking_widgets.dart';

enum OfferOutcome { accepted, declined, expired, cancelled }

/// Maps a realtime event to this offer's outcome, or null if it isn't about it.
OfferOutcome? outcomeFromEvent(
  RealtimeEvent event, {
  required String offerId,
  required String orderId,
}) {
  final data = event.data;
  switch (event.kind) {
    case RealtimeEventKind.offerResolved:
      final matches =
          data['offer_id'] == offerId ||
          (data['offer_id'] == null && data['order_id'] == orderId);
      if (!matches) return null;
      return switch (data['outcome']) {
        'accepted' => OfferOutcome.accepted,
        'declined' => OfferOutcome.declined,
        'expired' => OfferOutcome.expired,
        _ => null,
      };
    case RealtimeEventKind.orderUpdated:
      if (data['order_id'] != orderId) return null;
      return switch (data['status']) {
        'accepted' => OfferOutcome.accepted,
        'cancelled' => OfferOutcome.cancelled,
        _ => null,
      };
    default:
      return null;
  }
}

/// Waiting for the rider to answer: server-enforced countdown ring plus cancel.
class OfferWaitingScreen extends ConsumerStatefulWidget {
  const OfferWaitingScreen({super.key, required this.pending});

  /// After the countdown ends, how long to wait for the realtime outcome before asking the server.
  static const statusCheckDelay = Duration(seconds: 5);

  final PendingOffer pending;

  @override
  ConsumerState<OfferWaitingScreen> createState() => _OfferWaitingScreenState();
}

class _OfferWaitingScreenState extends ConsumerState<OfferWaitingScreen> {
  static const _tick = Duration(seconds: 1);
  static const _maxStatusChecks = 6;

  late final Duration _total;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  Timer? _statusTimer;
  int _statusChecks = 0;
  bool _resolved = false;
  bool _cancelling = false;

  Duration get _remaining {
    final r = _total - _elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  @override
  void initState() {
    super.initState();
    final offer = widget.pending.offer;
    final window =
        offer.serverWindow ?? offer.expiresAt.difference(DateTime.now());
    _total = window.isNegative ? Duration.zero : window;
    _ticker = Timer.periodic(_tick, (_) => _onTick());
    if (_total == Duration.zero) _scheduleStatusCheck();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    setState(() => _elapsed += _tick);
    if (_remaining == Duration.zero) {
      _ticker?.cancel();
      _scheduleStatusCheck();
    }
  }

  void _scheduleStatusCheck() {
    _statusTimer?.cancel();
    _statusTimer = Timer(OfferWaitingScreen.statusCheckDelay, _checkStatus);
  }

  /// Fallback for a missed realtime event once the server deadline has passed.
  Future<void> _checkStatus() async {
    if (_resolved || !mounted) return;
    _statusChecks++;
    try {
      final order = await ref
          .read(bookingRepositoryProvider)
          .getOrder(widget.pending.order.id);
      final outcome = switch (order.status) {
        'accepted' || 'started' || 'completed' => OfferOutcome.accepted,
        'created' || 'expired' => OfferOutcome.expired,
        'cancelled' => OfferOutcome.cancelled,
        _ => null,
      };
      if (outcome != null) {
        _resolve(outcome);
        return;
      }
    } catch (_) {
      // Network trouble: try again below.
    }
    if (!_resolved && mounted && _statusChecks < _maxStatusChecks) {
      _scheduleStatusCheck();
    }
  }

  void _resolve(OfferOutcome outcome) {
    if (_resolved || !mounted) return;
    _resolved = true;
    _ticker?.cancel();
    _statusTimer?.cancel();
    unawaited(ref.read(pendingOfferStoreProvider).clear());
    final p = widget.pending;
    switch (outcome) {
      case OfferOutcome.accepted:
        context.go(
          AppRoutes.trackingFor(p.order.id),
          extra: TrackingArgs(
            riderId: p.rider.riderId,
            riderName: p.rider.displayName,
            riderHasPhoto: p.rider.hasPhoto,
            breakdown: p.rider.breakdown,
          ),
        );
      case OfferOutcome.declined:
      case OfferOutcome.expired:
        context.go(
          AppRoutes.ridersFor(p.order.id),
          extra: RiderListArgs(
            order: p.order,
            notice: outcome == OfferOutcome.declined
                ? RiderListNotice.offerDeclined
                : RiderListNotice.offerExpired,
          ),
        );
      case OfferOutcome.cancelled:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).orderCancelledMessage),
          ),
        );
        context.go(AppRoutes.home);
    }
  }

  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('waiting.cancelDialog'),
        title: Text(l.cancelConfirmTitle),
        content: Text(l.cancelConfirmBody),
        actions: [
          TextButton(
            key: const Key('waiting.cancelDialog.no'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancelConfirmNo),
          ),
          TextButton(
            key: const Key('waiting.cancelDialog.yes'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.cancelConfirmYes),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _resolved) return;
    setState(() => _cancelling = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .cancelOrder(widget.pending.order.id);
      _resolve(OfferOutcome.cancelled);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('waiting.cancelFailed'),
          content: Text(l.cancelFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (_, next) {
      final event = next.value;
      if (event == null) return;
      final outcome = outcomeFromEvent(
        event,
        offerId: widget.pending.offer.id,
        orderId: widget.pending.order.id,
      );
      if (outcome != null) _resolve(outcome);
    });

    final l = AppLocalizations.of(context);
    final c = context.colors;
    final p = widget.pending;
    final total = p.offer.quotedTotal ?? p.rider.total;
    final expired = _remaining == Duration.zero;
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('screen.offerWaiting'),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l.waitingTitle(p.rider.displayName)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppLayout.screenPadding),
            children: [
              const SizedBox(height: AppSpacing.s4),
              Center(
                child: CountdownRing(remaining: _remaining, total: _total),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                expired ? l.waitingChecking : l.waitingBody,
                key: const Key('waiting.status'),
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: AppSpacing.s6),
              RiderSummaryTile(rider: p.rider),
              const SizedBox(height: AppSpacing.s3),
              SurfaceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.youPay,
                        style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                      ),
                    ),
                    Text(
                      formatKes(total),
                      key: const Key('waiting.total'),
                      style: AppTextStyles.displaySm.copyWith(color: c.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              OutlinedButton(
                key: const Key('waiting.cancel'),
                onPressed: _cancelling ? null : _cancel,
                child: Text(l.cancelRequestButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
