import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/data/booking_models.dart';
import '../booking/widgets/booking_widgets.dart';
import '../orders/data/order_models.dart';

/// The agreed terms behind the small "View terms" link (decision 7): route, price, pickup window.
/// [terms] is the server's snapshot from acceptance; [breakdown] is a fallback from the booking flow.
Future<void> showTermsSheet(
  BuildContext context, {
  required Order order,
  OrderTerms? terms,
  QuoteBreakdown? breakdown,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => TermsSheet(order: order, terms: terms, breakdown: breakdown),
);

class TermsSheet extends StatelessWidget {
  const TermsSheet({
    super.key,
    required this.order,
    this.terms,
    this.breakdown,
  });

  final Order order;
  final OrderTerms? terms;
  final QuoteBreakdown? breakdown;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final b = terms?.breakdown ?? breakdown ?? order.quoteBreakdown;
    final total = terms?.total ?? order.agreedPrice;
    final window = terms?.pickupWindowMins ?? order.pickupWindowMins;
    final tripKm = terms?.tripDistanceKm ?? order.distanceKm;
    Widget line(String label, String value, {String? detail, Key? key}) =>
        Padding(
          key: key,
          padding: const EdgeInsets.only(bottom: AppSpacing.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                    ),
                    if (detail != null)
                      Text(
                        detail,
                        style: AppTextStyles.labelSm.copyWith(
                          color: c.inkFaint,
                        ),
                      ),
                  ],
                ),
              ),
              Text(value, style: AppTextStyles.mono.copyWith(color: c.ink)),
            ],
          ),
        );
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('terms.sheet'),
        padding: const EdgeInsets.fromLTRB(
          AppLayout.screenPadding,
          0,
          AppLayout.screenPadding,
          AppSpacing.s6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.termsTitle,
              style: AppTextStyles.displaySm.copyWith(color: c.ink),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              l.termsLockedNote,
              style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s4),
            RouteSummary(
              pickup: order.pickupAddress,
              dropoff: order.dropoffAddress,
              trailing: tripKm == null
                  ? null
                  : InfoChip(l.tripDistance(formatKm(tripKm))),
            ),
            const SizedBox(height: AppSpacing.s4),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (b != null) ...[
                    line(l.breakdownBaseFare, formatKes(b.baseFare)),
                    line(
                      l.breakdownPlatform(formatKm(b.platformKm)),
                      formatKes(b.platformAmount),
                    ),
                    if (b.riderKm > 0)
                      line(
                        l.breakdownRider(formatKm(b.platformKm)),
                        formatKes(b.riderAmount),
                        detail: l.breakdownRiderDetail(
                          formatKm(b.riderKm),
                          formatKesRate(b.riderRate),
                        ),
                      ),
                    if (b.minimumFareApplied) NoteRow(l.breakdownMinimumFare),
                    const Divider(),
                  ],
                  line(
                    l.breakdownTotal,
                    total == null ? '—' : formatKes(total),
                    key: const Key('terms.total'),
                  ),
                  if (window != null)
                    line(
                      l.termsPickupWindow,
                      l.minutesShort(window),
                      key: const Key('terms.window'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
