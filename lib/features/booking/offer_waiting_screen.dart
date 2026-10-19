import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/errors/error_messages.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/realtime/realtime_event.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../common/confirm_dialog.dart';
import '../tracking/tracking_screen.dart';
import 'booking_routes.dart';
import 'data/booking_models.dart';
import 'resume.dart';
import 'rider_profile_screen.dart';
import 'widgets/booking_widgets.dart';

enum OfferOutcome { accepted, declined, expired, cancelled }

/// True for an `offer.resolved` about this offer, whatever its outcome (including outcomes
/// this build doesn't know): the offer is over and the server says what is current.
bool resolvesOffer(
  RealtimeEvent event, {
  required String offerId,
  required String orderId,
}) {
  if (event.kind != RealtimeEventKind.offerResolved) return false;
  final data = event.data;
  return data['offer_id'] == offerId ||
      (data['offer_id'] == null && data['order_id'] == orderId);
}

/// Maps a realtime event to this offer's outcome, or null if it isn't about it or the
/// outcome is one this build doesn't know (see [resolvesOffer]).
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

class _OfferWaitingScreenState extends ConsumerState<OfferWaitingScreen>
    with WidgetsBindingObserver {
  static const _tick = Duration(seconds: 1);
  static const _maxStatusChecks = 6;

  late PendingOffer _pending;
  Duration _total = Duration.zero;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  Timer? _statusTimer;
  int _statusChecks = 0;
  bool _resolved = false;
  bool _cancelling = false;
  bool _refreshing = false;

  Duration get _remaining {
    final r = _total - _elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pending = widget.pending;
    _markOpened();
    _startCountdown(fromServer: _pending.fromServer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  void _markOpened() => ref
      .read(sessionFlagsProvider)
      .openedLiveScreens
      .add(waitingScreenKey(_pending.offer.id));

  /// A just-sent offer starts at the server's full window (clock-skew free); an offer read
  /// back from the server counts down to its `expires_at`.
  void _startCountdown({required bool fromServer}) {
    final offer = _pending.offer;
    final window = offer.serverWindow;
    var remaining = fromServer || window == null
        ? offer.expiresAt.difference(ref.read(serverNowProvider)())
        : window;
    if (remaining.isNegative) remaining = Duration.zero;
    if (window != null && remaining > window) remaining = window;
    _total = window ?? remaining;
    _elapsed = _total - remaining;
    _ticker?.cancel();
    _statusTimer?.cancel();
    if (remaining == Duration.zero) {
      _scheduleStatusCheck();
    } else {
      _ticker = Timer.periodic(_tick, (_) => _onTick());
    }
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
    final applied = await _refresh();
    if (!applied &&
        !_resolved &&
        mounted &&
        _remaining == Duration.zero &&
        _statusChecks < _maxStatusChecks) {
      _scheduleStatusCheck();
    }
  }

  /// Re-reads the order (with its live offer) from the server so the screen never shows a
  /// stale offer. [ended] is the outcome a realtime event reported for the shown offer.
  /// Returns true when the screen was resolved or shows a live offer.
  Future<bool> _refresh({OfferOutcome? ended}) async {
    if (_resolved || !mounted || _refreshing) return false;
    _refreshing = true;
    try {
      final view = await ref
          .read(bookingRepositoryProvider)
          .senderOrder(_pending.order.id);
      if (!mounted || _resolved) return false;
      return _apply(view, ended: ended);
    } catch (_) {
      // Network trouble: trust the event when there was one, otherwise try again later.
      if (ended != null) {
        _resolve(ended);
        return true;
      }
      return false;
    } finally {
      _refreshing = false;
    }
  }

  bool _apply(SenderOrder view, {OfferOutcome? ended}) {
    final offer = view.offer;
    final rider = view.rider;
    if (offer != null &&
        rider != null &&
        (ended == null || offer.id != _pending.offer.id)) {
      setState(() {
        _pending = PendingOffer(
          order: view.order,
          rider: rider,
          offer: offer,
          fromServer: true,
        );
        _markOpened();
        _startCountdown(fromServer: true);
      });
      return _remaining > Duration.zero;
    }
    final status = view.order.status;
    final outcome = switch (status) {
      'cancelled' => OfferOutcome.cancelled,
      'completed' => OfferOutcome.accepted,
      _ when activeJobStatuses.contains(status) => OfferOutcome.accepted,
      'created' || 'expired' => ended ?? OfferOutcome.expired,
      // Still "offered" with no live offer: it has just ended server-side.
      _ => ended,
    };
    if (outcome != null) {
      _resolve(outcome);
      return true;
    }
    if (_remaining > Duration.zero) {
      _ticker?.cancel();
      setState(() => _elapsed = _total);
      _scheduleStatusCheck();
    }
    return false;
  }

  void _onOutcome(OfferOutcome outcome) {
    switch (outcome) {
      case OfferOutcome.accepted || OfferOutcome.cancelled:
        _resolve(outcome);
      case OfferOutcome.declined || OfferOutcome.expired:
        unawaited(_refresh(ended: outcome));
    }
  }

  void _resolve(OfferOutcome outcome) {
    if (_resolved || !mounted) return;
    _resolved = true;
    _ticker?.cancel();
    _statusTimer?.cancel();
    final p = _pending;
    switch (outcome) {
      case OfferOutcome.accepted:
        ref
            .read(sessionFlagsProvider)
            .openedLiveScreens
            .add(trackingScreenKey(p.order.id));
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
      await ref.read(bookingRepositoryProvider).cancelOrder(_pending.order.id);
      _resolve(OfferOutcome.cancelled);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (!e.isConflict) {
        setState(() => _cancelling = false);
        showSnack(
          context,
          l.cancelFailed,
          key: const Key('waiting.cancelFailed'),
        );
        return;
      }
      // Lost the race (e.g. the rider just accepted): show it and follow the server.
      showSnack(
        context,
        conflictText(e, l),
        key: const Key('waiting.conflict'),
      );
      setState(() => _cancelling = false);
      await _refresh();
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
      if (event.kind == RealtimeEventKind.connected) {
        unawaited(_refresh());
        return;
      }
      final outcome = outcomeFromEvent(
        event,
        offerId: _pending.offer.id,
        orderId: _pending.order.id,
      );
      if (outcome != null) {
        _onOutcome(outcome);
      } else if (resolvesOffer(
        event,
        offerId: _pending.offer.id,
        orderId: _pending.order.id,
      )) {
        unawaited(_refresh());
      }
    });

    final l = AppLocalizations.of(context);
    final c = context.colors;
    final p = _pending;
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
