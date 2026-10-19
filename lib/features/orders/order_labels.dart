import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/data/booking_models.dart';

String orderStatusLabel(AppLocalizations l, Order o) => switch (o.status) {
  'created' => l.statusCreated,
  'offered' || 'awaiting_match' => l.statusOffered,
  'accepted' => l.statusAccepted,
  'started' || 'in_transit' => l.statusInTransit,
  'arrived' => l.statusArrived,
  'payment_requested' || 'cash_pending' => l.statusPayment,
  'paid' => l.statusPaid,
  'handed_over' =>
    o.serviceType == ServiceType.ride ? l.statusDroppedOff : l.statusHandedOver,
  'completed' => l.statusCompleted,
  'cancelled' => l.statusCancelled,
  'expired' => l.statusExpired,
  'payment_failed' => l.statusPaymentFailed,
  'unresolved' => l.statusUnresolved,
  _ => o.status,
};

enum _Tone { success, danger, live, neutral }

_Tone _toneOf(String status) => switch (status) {
  'completed' => _Tone.success,
  'cancelled' || 'expired' || 'payment_failed' || 'unresolved' => _Tone.danger,
  'created' || 'offered' || 'awaiting_match' => _Tone.neutral,
  _ => _Tone.live,
};

/// Status pill: a colored dot plus the localized status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dot = switch (_toneOf(order.status)) {
      _Tone.success => c.statusSuccess,
      _Tone.danger => c.statusError,
      _Tone.live => c.statusInfo,
      _Tone.neutral => c.statusNeutral,
    };
    return Container(
      key: Key('status.${order.status}'),
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
          Container(
            width: AppSpacing.s2,
            height: AppSpacing.s2,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s1),
          Text(
            orderStatusLabel(AppLocalizations.of(context), order),
            style: AppTextStyles.label.copyWith(color: c.ink),
          ),
        ],
      ),
    );
  }
}

/// Five stars, read-only.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: AppLocalizations.of(context).ratingStarsLabel(score),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                i <= score ? Icons.star : Icons.star_border,
                size: AppSpacing.s5,
                color: i <= score ? c.brand500 : c.inkFaint,
              ),
          ],
        ),
      ),
    );
  }
}
