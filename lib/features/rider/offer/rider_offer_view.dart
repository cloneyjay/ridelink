import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../booking/booking_labels.dart';
import '../../booking/widgets/booking_widgets.dart';
import '../data/rider_models.dart';
import '../rider_controller.dart';

/// Screen 6: a sender's request with the server-enforced countdown, earnings and pickup terms.
class RiderOfferView extends ConsumerStatefulWidget {
  const RiderOfferView({super.key, required this.offer});

  /// After the countdown ends, how long to wait for offer.resolved before asking the server.
  static const statusCheckDelay = Duration(seconds: 5);

  final RiderOffer offer;

  @override
  ConsumerState<RiderOfferView> createState() => _RiderOfferViewState();
}

class _RiderOfferViewState extends ConsumerState<RiderOfferView> {
  static const _tick = Duration(seconds: 1);

  late Duration _total;
  late Duration _remaining;
  Timer? _ticker;
  Timer? _check;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(RiderOfferView old) {
    super.didUpdateWidget(old);
    if (old.offer.id != widget.offer.id) _start();
  }

  void _start() {
    _ticker?.cancel();
    _check?.cancel();
    _error = null;
    _total = widget.offer.window;
    // On resume the phone clock is the only reference for time already spent.
    final now = ref.read(clockProvider)();
    final left = widget.offer.expiresAt.difference(now);
    _remaining = left < _total
        ? (left.isNegative ? Duration.zero : left)
        : _total;
    if (_remaining == Duration.zero) {
      _scheduleCheck();
    } else {
      _ticker = Timer.periodic(_tick, (_) => _onTick());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _check?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    final next = _remaining - _tick;
    setState(() => _remaining = next.isNegative ? Duration.zero : next);
    if (_remaining == Duration.zero) {
      _ticker?.cancel();
      _scheduleCheck();
    }
  }

  void _scheduleCheck() {
    _check = Timer(RiderOfferView.statusCheckDelay, () {
      if (mounted) ref.read(riderControllerProvider.notifier).refreshActive();
    });
  }

  Future<void> _accept() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(riderControllerProvider.notifier)
        .acceptOffer();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = switch (result) {
        AcceptResult.needsLocation => l.acceptNeedsLocation,
        AcceptResult.failed => l.acceptFailed,
        _ => null,
      };
    });
  }

  Future<void> _decline() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(riderControllerProvider.notifier).declineOffer();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _error = l.declineFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final o = widget.offer;
    final expired = _remaining == Duration.zero;
    final accent = serviceAccent(c, o.serviceType);
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('screen.riderOffer'),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l.riderOfferTitle),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppLayout.screenPadding),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s1,
                  ),
                  decoration: BoxDecoration(
                    color: serviceTint(c, o.serviceType),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        serviceIcon(o.serviceType),
                        color: accent,
                        size: AppSpacing.s5,
                      ),
                      const SizedBox(width: AppSpacing.s1),
                      Text(
                        serviceName(l, o.serviceType),
                        key: const Key('offer.service'),
                        style: AppTextStyles.label.copyWith(color: c.ink),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Center(
                child: CountdownRing(remaining: _remaining, total: _total),
              ),
              if (expired) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(
                  l.riderOfferChecking,
                  key: const Key('offer.expired'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: c.inkMuted),
                ),
              ],
              const SizedBox(height: AppSpacing.s4),
              Text(
                l.youEarn,
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(color: c.inkMuted),
              ),
              Text(
                o.quotedTotal == null ? '—' : formatKes(o.quotedTotal!),
                key: const Key('offer.earnings'),
                textAlign: TextAlign.center,
                style: AppTextStyles.displayXl.copyWith(color: c.ink),
              ),
              const SizedBox(height: AppSpacing.s4),
              RouteSummary(
                pickup: o.pickupAddress,
                dropoff: o.dropoffAddress,
                trailing: o.distanceKm == null
                    ? null
                    : InfoChip(
                        o.distanceEstimated
                            ? '${l.tripDistance(formatKm(o.distanceKm!))} · ${l.distanceEstimatedNote}'
                            : l.tripDistance(formatKm(o.distanceKm!)),
                        key: const Key('offer.tripDistance'),
                        icon: Icons.route,
                      ),
              ),
              const SizedBox(height: AppSpacing.s3),
              SurfaceCard(
                child: Row(
                  children: [
                    Icon(Icons.near_me_outlined, color: c.forest500),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (o.pickupDistanceKm != null)
                            Text(
                              l.pickupDistanceAway(
                                formatKm(o.pickupDistanceKm!),
                              ),
                              key: const Key('offer.pickupDistance'),
                              style: AppTextStyles.labelLg.copyWith(
                                color: c.ink,
                              ),
                            ),
                          if (o.pickupWindowMins != null)
                            Text(
                              l.reachPickupWithin(o.pickupWindowMins!),
                              key: const Key('offer.pickupWindow'),
                              style: AppTextStyles.bodySm.copyWith(
                                color: c.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s3),
                InlineError(_error!, key: const Key('offer.error')),
              ],
              const SizedBox(height: AppSpacing.s6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('offer.decline'),
                      onPressed: _busy || expired ? null : _decline,
                      child: Text(l.declineButton),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      key: const Key('offer.accept'),
                      label: l.acceptButton,
                      loading: _busy,
                      onPressed: expired ? null : _accept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
