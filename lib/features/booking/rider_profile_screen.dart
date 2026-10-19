import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'booking_labels.dart';
import 'booking_routes.dart';
import 'data/booking_models.dart';
import 'rider_list_screen.dart';
import 'widgets/booking_widgets.dart';

/// Screen 3: the rider's public stats and this trip's price breakdown.
class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key, required this.choice});

  final RiderChoice choice;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final rider = choice.rider;
    const dash = '–';
    return Scaffold(
      key: const Key('screen.riderProfile'),
      appBar: AppBar(title: Text(l.riderProfileTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [
            SurfaceCard(
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: Column(
                children: [
                  RiderAvatar(
                    riderId: rider.riderId,
                    name: rider.displayName,
                    hasPhoto: rider.hasPhoto,
                    size: AppSpacing.s16,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    rider.displayName,
                    style: AppTextStyles.displayMd.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s2,
                      vertical: AppSpacing.s1,
                    ),
                    decoration: BoxDecoration(
                      color: serviceTint(c, choice.order.serviceType),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          serviceIcon(choice.order.serviceType),
                          size: AppSpacing.s4,
                          color: serviceAccent(c, choice.order.serviceType),
                        ),
                        const SizedBox(width: AppSpacing.s1),
                        Text(
                          serviceName(l, choice.order.serviceType),
                          style: AppTextStyles.label.copyWith(
                            color: serviceAccent(c, choice.order.serviceType),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.s2,
              crossAxisSpacing: AppSpacing.s2,
              childAspectRatio: 1.6,
              children: [
                _Stat(
                  key: const Key('profile.stat.rating'),
                  label: l.statRating,
                  value: rider.ratingCount == 0
                      ? dash
                      : rider.ratingAverage.toStringAsFixed(1),
                  caption: rider.ratingCount == 0
                      ? l.noRatingsYet
                      : l.ratingCount(rider.ratingCount),
                ),
                _Stat(
                  key: const Key('profile.stat.onTime'),
                  label: l.statOnTime,
                  value: rider.onTimeRate == null
                      ? dash
                      : '${(rider.onTimeRate! * 100).round()}%',
                ),
                _Stat(
                  key: const Key('profile.stat.completed'),
                  label: l.statCompleted,
                  value: rider.completed?.toString() ?? dash,
                ),
                _Stat(
                  key: const Key('profile.stat.pickup'),
                  label: l.statPickup,
                  value: formatKm(rider.pickupDistanceKm),
                  caption: l.arrivesWithin(rider.pickupWindowMins),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            PriceBreakdownCard(rider: rider),
            const SizedBox(height: AppSpacing.s6),
            PrimaryButton(
              key: const Key('profile.request'),
              label: l.requestButton,
              onPressed: () => context.push(
                AppRoutes.quoteFor(choice.order.id),
                extra: choice,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    super.key,
    required this.label,
    required this.value,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.labelSm.copyWith(color: c.inkMuted)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.displayMd.copyWith(color: c.ink),
            ),
          ),
          if (caption != null)
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: c.inkMuted),
            ),
        ],
      ),
    );
  }
}

/// This trip's price from the quote breakdown; the server's `total` is always the price shown.
class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({super.key, required this.rider});

  final RiderQuote rider;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final b = rider.breakdown;
    Widget row(String label, int amount, {Key? key, String? detail}) => Padding(
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
                    style: AppTextStyles.labelSm.copyWith(color: c.inkFaint),
                  ),
              ],
            ),
          ),
          Text(
            formatKes(amount),
            style: AppTextStyles.mono.copyWith(color: c.ink),
          ),
        ],
      ),
    );

    return SurfaceCard(
      key: const Key('profile.breakdown'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.priceForThisTrip,
            style: AppTextStyles.labelLg.copyWith(color: c.ink),
          ),
          const SizedBox(height: AppSpacing.s3),
          row(l.breakdownBaseFare, b.baseFare),
          row(
            l.breakdownPlatform(formatKm(b.platformKm)),
            b.platformAmount,
            key: const Key('profile.breakdown.platform'),
          ),
          if (b.riderKm > 0)
            row(
              l.breakdownRider(formatKm(b.platformKm)),
              b.riderAmount,
              key: const Key('profile.breakdown.rider'),
              detail: l.breakdownRiderDetail(
                formatKm(b.riderKm),
                formatKesRate(b.riderRate),
              ),
            ),
          if (b.minimumFareApplied)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: NoteRow(
                l.breakdownMinimumFare,
                key: const Key('profile.breakdown.minimum'),
              ),
            ),
          const Divider(),
          const SizedBox(height: AppSpacing.s2),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.breakdownTotal,
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
              ),
              Text(
                formatKes(rider.total),
                key: const Key('profile.total'),
                style: AppTextStyles.displayMd.copyWith(color: c.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact rider summary reused on the quote and waiting screens.
class RiderSummaryTile extends StatelessWidget {
  const RiderSummaryTile({super.key, required this.rider});

  final RiderQuote rider;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return SurfaceCard(
      child: Row(
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
                RatingLine(rider: rider),
                Text(
                  l.arrivesWithin(rider.pickupWindowMins),
                  style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
