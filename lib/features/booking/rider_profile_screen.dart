import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../profile/public/public_profile_providers.dart';
import '../profile/public/public_profile_view.dart';
import 'booking_labels.dart';
import 'booking_routes.dart';
import 'data/booking_models.dart';
import 'rider_list_screen.dart';
import 'widgets/booking_widgets.dart';

/// Screen 3: the rider's shared public profile (GET /riders/{id}/public-profile), then this
/// trip's pickup terms and price breakdown from the quote.
class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key, required this.choice});

  final RiderChoice choice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final rider = choice.rider;
    final profile = ref.watch(riderPublicProfileProvider(rider.riderId));
    final trip = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
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
        const SizedBox(height: AppSpacing.s2),
        _Stat(
          key: const Key('profile.stat.pickup'),
          label: l.statPickup,
          value: formatKm(rider.pickupDistanceKm),
          caption: l.arrivesWithin(rider.pickupWindowMins),
        ),
        const SizedBox(height: AppSpacing.s3),
        PriceBreakdownCard(rider: rider),
        const SizedBox(height: AppSpacing.s6),
        PrimaryButton(
          key: const Key('profile.request'),
          label: l.requestButton,
          onPressed: () =>
              context.push(AppRoutes.quoteFor(choice.order.id), extra: choice),
        ),
      ],
    );
    final Widget content;
    if (profile.hasValue) {
      content = PublicProfileView(profile: profile.value!, below: trip);
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile.hasError)
            SurfaceCard(
              key: const Key('publicProfile.error'),
              child: Column(
                children: [
                  Text(
                    l.publicProfileLoadFailed,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  OutlinedButton(
                    key: const Key('publicProfile.retry'),
                    onPressed: () => ref.invalidate(
                      riderPublicProfileProvider(rider.riderId),
                    ),
                    child: Text(l.retryButton),
                  ),
                ],
              ),
            )
          else
            const SizedBox(
              key: Key('publicProfile.loading'),
              height: AppSpacing.s16 * 2,
              child: LoadingView(),
            ),
          const SizedBox(height: AppSpacing.s3),
          trip,
        ],
      );
    }
    return Scaffold(
      key: const Key('screen.riderProfile'),
      appBar: AppBar(title: Text(l.riderProfileTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [content],
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
