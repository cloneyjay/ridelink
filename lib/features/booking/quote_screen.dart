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
import 'booking_routes.dart';
import 'rider_profile_screen.dart';
import 'widgets/booking_widgets.dart';

/// Screen 5: final quote (no negotiation), then send the request to the rider.
class QuoteScreen extends ConsumerStatefulWidget {
  const QuoteScreen({super.key, required this.choice});

  final RiderChoice choice;

  @override
  ConsumerState<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends ConsumerState<QuoteScreen> {
  bool _sending = false;
  String? _error;

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    final choice = widget.choice;
    try {
      final offer = await ref
          .read(bookingRepositoryProvider)
          .sendOffer(orderId: choice.order.id, riderId: choice.rider.riderId);
      await ref.read(pendingOfferStoreProvider).save(offer, choice.rider);
      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.waitingFor(choice.order.id),
        extra: PendingOffer(
          order: choice.order,
          rider: choice.rider,
          offer: offer,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = apiErrorText(e, l, fallback: l.sendRequestFailed);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final order = widget.choice.order;
    final rider = widget.choice.rider;
    return Scaffold(
      key: const Key('screen.quote'),
      appBar: AppBar(title: Text(l.quoteTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [
            RiderSummaryTile(rider: rider),
            const SizedBox(height: AppSpacing.s3),
            RouteSummary(
              pickup: order.pickupAddress,
              dropoff: order.dropoffAddress,
              trailing: order.distanceKm == null
                  ? null
                  : InfoChip(l.tripDistance(formatKm(order.distanceKm!))),
            ),
            const SizedBox(height: AppSpacing.s3),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.youPay,
                    style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    formatKes(rider.total),
                    key: const Key('quote.total'),
                    style: AppTextStyles.displayXl.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  NoteRow(
                    l.quoteFinalNote,
                    key: const Key('quote.finalNote'),
                    icon: Icons.lock_outline,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s4),
              InlineError(_error!, key: const Key('quote.error')),
            ],
            const SizedBox(height: AppSpacing.s6),
            PrimaryButton(
              key: const Key('quote.send'),
              label: l.sendRequestButton,
              loading: _sending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
