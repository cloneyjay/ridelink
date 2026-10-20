import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_text_styles.dart';
import '../booking_labels.dart';

final riderPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>(
      (ref, riderId) =>
          ref.watch(bookingRepositoryProvider).riderPhoto(riderId),
      retry: (_, _) => null,
    );

/// Rider photo, or initials when there is no photo (has_photo false, 404 or error).
class RiderAvatar extends ConsumerWidget {
  const RiderAvatar({
    super.key,
    required this.riderId,
    required this.name,
    required this.hasPhoto,
    this.size = AppSpacing.s12,
  });

  final String riderId;
  final String name;
  final bool hasPhoto;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bytes = hasPhoto
        ? ref.watch(riderPhotoProvider(riderId)).value
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: SizedBox.square(
        dimension: size,
        child: bytes != null
            ? Image.memory(
                bytes,
                key: Key('rider.photo.$riderId'),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _Initials(name: name),
              )
            : ColoredBox(
                color: c.brand100,
                child: _Initials(name: name),
              ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      initialsOf(name),
      style: AppTextStyles.labelLg.copyWith(color: context.colors.brand700),
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(AppSpacing.s4),
    decoration: BoxDecoration(
      color: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: context.shadows.sm,
    ),
    child: child,
  );
}

/// Pickup -> drop-off with an optional trailing chip (e.g. trip distance).
class RouteSummary extends StatelessWidget {
  const RouteSummary({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.trailing,
  });

  final String pickup;
  final String dropoff;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    Widget row(IconData icon, Color color, String label, String value) => Row(
      children: [
        Icon(icon, color: color, size: AppSpacing.s5),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(color: c.inkMuted),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(color: c.ink),
              ),
            ],
          ),
        ),
      ],
    );
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(Icons.location_on, c.forest500, l.pickupLabel, pickup),
          const SizedBox(height: AppSpacing.s3),
          row(Icons.flag, c.brand500, l.dropoffLabel, dropoff),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.s3),
            Align(alignment: Alignment.centerLeft, child: trailing),
          ],
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

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
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.s4, color: c.inkMuted),
            const SizedBox(width: AppSpacing.s1),
          ],
          Text(text, style: AppTextStyles.label.copyWith(color: c.inkMuted)),
        ],
      ),
    );
  }
}

/// Muted note with a leading icon.
class NoteRow extends StatelessWidget {
  const NoteRow(this.text, {super.key, this.icon = Icons.info_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSpacing.s4, color: c.inkMuted),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// Full-area message with an optional action (empty and error states).
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.s12, color: c.inkFaint),
            const SizedBox(height: AppSpacing.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.displaySm.copyWith(color: c.ink),
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: c.inkMuted),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.s6),
              OutlinedButton(
                key: actionKey,
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: c.statusErrorTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySm.copyWith(color: c.statusError),
      ),
    );
  }
}

/// Tappable pickup / drop-off fields that open the place search.
class RouteFields extends StatelessWidget {
  const RouteFields({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.onPickup,
    required this.onDropoff,
    this.pickupError,
    this.dropoffError,
    this.pickupLoading = false,
  });

  final String? pickup;
  final String? dropoff;
  final VoidCallback onPickup;
  final VoidCallback onDropoff;
  final String? pickupError;
  final String? dropoffError;

  /// The current location is being read for the default pickup.
  final bool pickupLoading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    Widget field({
      required Key key,
      required IconData icon,
      required Color color,
      required String label,
      required String placeholder,
      required String? value,
      required String? error,
      required VoidCallback onTap,
      Widget? trailing,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppLayout.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
              child: Row(
                children: [
                  Icon(icon, color: color, size: AppSpacing.s5),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.labelSm.copyWith(
                            color: c.inkMuted,
                          ),
                        ),
                        Text(
                          value ?? placeholder,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: value == null ? c.inkFaint : c.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing ?? Icon(Icons.chevron_right, color: c.inkFaint),
                ],
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s8),
            child: Text(
              error,
              style: AppTextStyles.bodySm.copyWith(color: c.statusError),
            ),
          ),
      ],
    );

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s2,
      ),
      child: Column(
        children: [
          field(
            key: const Key('route.pickup'),
            icon: Icons.location_on,
            color: c.forest500,
            label: l.pickupLabel,
            placeholder: pickupLoading
                ? l.findingLocationLabel
                : l.choosePickup,
            value: pickup,
            error: pickupError,
            onTap: onPickup,
            trailing: pickupLoading
                ? SizedBox.square(
                    key: const Key('route.pickup.locating'),
                    dimension: AppSpacing.s5,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.inkMuted,
                    ),
                  )
                : pickup == null
                ? null
                : TextButton(
                    key: const Key('route.pickup.change'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        AppLayout.minTapTarget,
                        AppLayout.minTapTarget,
                      ),
                    ),
                    onPressed: onPickup,
                    child: Text(l.changeButton),
                  ),
          ),
          const Divider(),
          field(
            key: const Key('route.dropoff'),
            icon: Icons.flag,
            color: c.brand500,
            label: l.dropoffLabel,
            placeholder: l.chooseDropoff,
            value: dropoff,
            error: dropoffError,
            onTap: onDropoff,
          ),
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      Center(child: CircularProgressIndicator(color: context.colors.brand500));
}

/// Primary button with an inline spinner while [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: loading ? null : onPressed,
    child: loading
        ? SizedBox.square(
            dimension: AppSpacing.s5,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.inkOnBrand,
            ),
          )
        : Text(label),
  );
}

/// Offer countdown ring; the only place `colors.countdown` is used.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    this.size = AppSpacing.s16 * 2,
  });

  final Duration remaining;
  final Duration total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final fraction = total.inMilliseconds <= 0
        ? 0.0
        : (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final seconds = (remaining.inMilliseconds / 1000).ceil().clamp(0, 9999);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: fraction,
          track: c.surfaceSunken,
          progress: c.countdown,
          stroke: AppSpacing.s2,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$seconds',
                key: const Key('countdown.seconds'),
                style: AppTextStyles.displayXl.copyWith(color: c.countdown),
              ),
              Text(
                l.secondsLabel,
                style: AppTextStyles.labelSm.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.track,
    required this.progress,
    required this.stroke,
  });

  final double fraction;
  final Color track;
  final Color progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(inset, 0, 2 * math.pi, false, base);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progress;
    canvas.drawArc(inset, -math.pi / 2, 2 * math.pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.track != track ||
      old.progress != progress;
}
