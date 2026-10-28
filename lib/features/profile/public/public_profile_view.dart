import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../booking/booking_labels.dart';
import '../../booking/widgets/booking_widgets.dart';
import 'public_profile_models.dart';
import 'public_profile_providers.dart';

/// "Joined Oct 2026" in the app language.
String joinedLabel(AppLocalizations l, DateTime joinedAt) =>
    l.publicProfileJoined(
      DateFormat.yMMM(l.localeName).format(joinedAt.toLocal()),
    );

/// A percentage, or "New on RideLink" when the sample is too small to show one.
String pctLabel(AppLocalizations l, int? pct) =>
    pct == null ? l.publicProfileNewOnRideLink : '$pct%';

/// One public-profile layout for both roles: header, 30-day stats, all-time count, [below].
class PublicProfileView extends StatelessWidget {
  const PublicProfileView({super.key, required this.profile, this.below});

  final PublicProfile profile;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final p = profile;
    final rider = p.role == PublicProfileRole.rider;
    const dash = '–';
    final rating = p.rating;
    final stats = rider
        ? [
            ProfileStat(
              key: const Key('publicProfile.stat.rating'),
              label: l.statRating,
              value: rating == null || rating.count == 0
                  ? dash
                  : rating.average.toStringAsFixed(1),
              caption: rating == null || rating.count == 0
                  ? l.noRatingsYet
                  : l.ratingCount(rating.count),
            ),
            ProfileStat(
              key: const Key('publicProfile.stat.onTime'),
              label: l.statOnTime,
              value: pctLabel(l, p.onTimePct),
              small: p.onTimePct == null,
            ),
            ProfileStat(
              key: const Key('publicProfile.stat.completed'),
              label: l.statCompleted,
              value: '${p.completed30d}',
            ),
            ProfileStat(
              key: const Key('publicProfile.stat.accept'),
              label: l.statAccepted,
              value: pctLabel(l, p.acceptPct),
              small: p.acceptPct == null,
            ),
            ProfileStat(
              key: const Key('publicProfile.stat.disputes'),
              label: l.statDisputes,
              value: pctLabel(l, p.disputePct),
              small: p.disputePct == null,
            ),
            ProfileStat(
              key: const Key('publicProfile.stat.positive'),
              label: l.statPositive,
              value: pctLabel(l, p.positivePct),
              small: p.positivePct == null,
            ),
          ]
        : [
            ProfileStat(
              key: const Key('publicProfile.stat.orders'),
              label: l.publicProfileOrders,
              value: '${p.orders30d}',
            ),
            ProfileStat(
              key: const Key('publicProfile.stat.paymentSuccess'),
              label: l.publicProfilePaymentSuccess,
              value: pctLabel(l, p.paymentSuccessPct),
              small: p.paymentSuccessPct == null,
            ),
            ProfileStat(
              key: const Key('publicProfile.stat.cancellations'),
              label: l.publicProfileCancellations,
              value: pctLabel(l, p.cancellationPct),
              small: p.cancellationPct == null,
            ),
          ];

    return Column(
      key: const Key('publicProfile.view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            children: [
              ProfileAvatar(profile: p, size: AppSpacing.s16),
              const SizedBox(height: AppSpacing.s3),
              Text(
                p.firstName,
                key: const Key('publicProfile.name'),
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMd.copyWith(color: c.ink),
              ),
              if (p.joinedAt != null) ...[
                const SizedBox(height: AppSpacing.s1),
                Text(
                  joinedLabel(l, p.joinedAt!),
                  key: const Key('publicProfile.joined'),
                  style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                ),
              ],
              if (p.newOnRideLink) ...[
                const SizedBox(height: AppSpacing.s2),
                const NewOnRideLinkChip(key: Key('publicProfile.newChip')),
              ],
              if (rider && p.isVerifiedRider) ...[
                const SizedBox(height: AppSpacing.s2),
                Container(
                  key: const Key('publicProfile.badge.verifiedRider'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s2,
                    vertical: AppSpacing.s1,
                  ),
                  decoration: BoxDecoration(
                    color: c.forest100,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: AppSpacing.s4,
                        color: c.forest500,
                      ),
                      const SizedBox(width: AppSpacing.s1),
                      Text(
                        l.publicProfileVerifiedRider,
                        style: AppTextStyles.label.copyWith(color: c.forest700),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          l.publicProfileLast30Days,
          style: AppTextStyles.labelLg.copyWith(color: c.ink),
        ),
        const SizedBox(height: AppSpacing.s2),
        for (var r = 0; r < stats.length; r += 3) ...[
          if (r > 0) const SizedBox(height: AppSpacing.s2),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = r; i < r + 3; i++) ...[
                  if (i > r) const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: i < stats.length ? stats[i] : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s3),
        SurfaceCard(
          key: const Key('publicProfile.allTime'),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  rider
                      ? l.publicProfileTripsAllTime
                      : l.publicProfileOrdersAllTime,
                  style: AppTextStyles.body.copyWith(color: c.inkMuted),
                ),
              ),
              Text(
                '${rider ? p.completedAllTime : p.ordersAllTime}',
                style: AppTextStyles.displaySm.copyWith(color: c.ink),
              ),
            ],
          ),
        ),
        if (below != null) ...[const SizedBox(height: AppSpacing.s3), below!],
      ],
    );
  }
}

/// A labelled figure; [small] renders a text value (e.g. "New on RideLink") at label size.
class ProfileStat extends StatelessWidget {
  const ProfileStat({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.small = false,
  });

  final String label;
  final String value;
  final String? caption;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s1),
          if (small)
            Text(value, style: AppTextStyles.label.copyWith(color: c.ink))
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTextStyles.displaySm.copyWith(color: c.ink),
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

/// "New on RideLink" chip, shown when the server marks the account new (new_on_ridelink).
class NewOnRideLinkChip extends StatelessWidget {
  const NewOnRideLinkChip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fiber_new_outlined,
            size: AppSpacing.s4,
            color: c.inkMuted,
          ),
          const SizedBox(width: AppSpacing.s1),
          Text(
            AppLocalizations.of(context).publicProfileNewOnRideLink,
            style: AppTextStyles.label.copyWith(color: c.ink),
          ),
        ],
      ),
    );
  }
}

/// Profile photo loaded as bytes through the Go server (never a direct network image);
/// initials when there is no photo or it fails to load.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, required this.profile, required this.size});

  final PublicProfile profile;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile;
    if (p.role == PublicProfileRole.rider) {
      return RiderAvatar(
        riderId: p.id,
        name: p.firstName,
        hasPhoto: p.photoUrl != null,
        size: size,
      );
    }
    final c = context.colors;
    final bytes = p.photoUrl == null
        ? null
        : ref.watch(senderPhotoProvider(p.id)).value;
    final initials = ColoredBox(
      color: c.brand100,
      child: Center(
        child: Text(
          initialsOf(p.firstName),
          style: AppTextStyles.labelLg.copyWith(color: c.brand700),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: SizedBox.square(
        dimension: size,
        child: bytes == null
            ? initials
            : Image.memory(
                bytes,
                key: Key('sender.photo.${p.id}'),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initials,
              ),
      ),
    );
  }
}
