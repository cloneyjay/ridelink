import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../profile/public/public_profile_models.dart';
import '../../profile/public/public_profile_providers.dart';
import '../../profile/public/public_profile_view.dart';

/// Screen 6 "sender trust" block. Renders nothing until the profile loads and nothing on
/// failure, so it never delays the offer or puts an error over the countdown.
class SenderTrustCard extends ConsumerWidget {
  const SenderTrustCard({
    super.key,
    required this.senderId,
    required this.onOpen,
  });

  final String senderId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(senderPublicProfileProvider(senderId));
    final p = profile.hasError ? null : profile.value;
    if (p == null) return const SizedBox.shrink();
    return _Card(profile: p, onOpen: onOpen);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.profile, required this.onOpen});

  final PublicProfile profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final p = profile;
    Widget stat(String label, String value, {required bool text}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm.copyWith(color: c.inkMuted),
          ),
          Text(
            value,
            style: (text ? AppTextStyles.label : AppTextStyles.displaySm)
                .copyWith(color: c.ink),
          ),
        ],
      ),
    );

    return Material(
      key: const Key('offer.senderTrust'),
      color: c.forest100,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ProfileAvatar(profile: p, size: AppSpacing.s8),
                    const SizedBox(width: AppSpacing.s2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.firstName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLg.copyWith(color: c.ink),
                          ),
                          Text(
                            l.publicProfileLast30Days,
                            style: AppTextStyles.labelSm.copyWith(
                              color: c.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (p.newOnRideLink) ...[
                      const NewOnRideLinkChip(
                        key: Key('offer.senderTrust.newChip'),
                      ),
                      const SizedBox(width: AppSpacing.s1),
                    ],
                    Icon(Icons.chevron_right, color: c.forest700),
                  ],
                ),
                const SizedBox(height: AppSpacing.s2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stat(l.publicProfileOrders, '${p.orders30d}', text: false),
                    const SizedBox(width: AppSpacing.s3),
                    stat(
                      l.publicProfilePaymentSuccess,
                      pctLabel(l, p.paymentSuccessPct),
                      text: p.paymentSuccessPct == null,
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    stat(
                      l.publicProfileCancellations,
                      pctLabel(l, p.cancellationPct),
                      text: p.cancellationPct == null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
