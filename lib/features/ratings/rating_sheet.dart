import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/data/booking_models.dart';
import '../booking/widgets/booking_widgets.dart';
import '../common/confirm_dialog.dart';
import '../orders/order_providers.dart';

const ratingCommentMax = 500;

/// Who is being rated, for the sheet's title.
enum RatingTarget { rider, sender, passenger }

RatingTarget ratingTargetFor(OrderRole myRole, ServiceType service) =>
    myRole == OrderRole.sender
    ? RatingTarget.rider
    : (service == ServiceType.ride
          ? RatingTarget.passenger
          : RatingTarget.sender);

/// Asks once per order and device after completion (skippable). Skips when this party has
/// already rated (e.g. on another device).
Future<void> maybePromptRating(
  BuildContext context,
  WidgetRef ref, {
  required Order order,
  required OrderRole role,
}) async {
  if (order.status != 'completed') return;
  final store = ref.read(ratingPromptStoreProvider);
  if (store.wasPrompted(order.id)) return;
  await store.markPrompted(order.id);
  final userId = ref.read(currentUserIdProvider);
  try {
    final ratings = await ref.read(ordersRepositoryProvider).ratings(order.id);
    if (ratings.any((r) => r.fromId == userId)) return;
  } catch (_) {
    // Can't tell; asking is harmless since the server rejects a second rating.
  }
  if (!context.mounted) return;
  await showRatingSheet(
    context,
    orderId: order.id,
    target: ratingTargetFor(role, order.serviceType),
  );
}

/// Returns true when a rating was saved (or the server says it already exists).
Future<bool> showRatingSheet(
  BuildContext context, {
  required String orderId,
  required RatingTarget target,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => RatingSheet(orderId: orderId, target: target),
  );
  return saved ?? false;
}

class RatingSheet extends ConsumerStatefulWidget {
  const RatingSheet({super.key, required this.orderId, required this.target});

  final String orderId;
  final RatingTarget target;

  @override
  ConsumerState<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<RatingSheet> {
  final _comment = TextEditingController();
  int _score = 0;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    final comment = _comment.text.trim();
    try {
      await ref
          .read(ordersRepositoryProvider)
          .submitRating(
            widget.orderId,
            score: _score,
            comment: comment.isEmpty ? null : comment,
          );
      ref.invalidate(orderRatingsProvider(widget.orderId));
      if (!mounted) return;
      showSnack(context, l.ratingThanks, key: const Key('rating.thanks'));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'already_rated' || e.statusCode == 409) {
        ref.invalidate(orderRatingsProvider(widget.orderId));
        showSnack(
          context,
          l.errCodeAlreadyRated,
          key: const Key('rating.already'),
        );
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _sending = false;
        _error = apiErrorText(e, l, fallback: l.ratingFailed);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = apiErrorText(e, l, fallback: l.ratingFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final title = switch (widget.target) {
      RatingTarget.rider => l.rateRiderTitle,
      RatingTarget.sender => l.rateSenderTitle,
      RatingTarget.passenger => l.ratePassengerTitle,
    };
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('rating.sheet'),
        padding: EdgeInsets.fromLTRB(
          AppLayout.screenPadding,
          0,
          AppLayout.screenPadding,
          AppSpacing.s6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.displaySm.copyWith(color: c.ink)),
            const SizedBox(height: AppSpacing.s1),
            Text(
              l.rateBody,
              style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    key: Key('rating.star.$i'),
                    tooltip: l.ratingStarsLabel(i),
                    constraints: const BoxConstraints(
                      minWidth: AppLayout.minTapTarget,
                      minHeight: AppLayout.minTapTarget,
                    ),
                    iconSize: AppSpacing.s8,
                    onPressed: _sending
                        ? null
                        : () => setState(() => _score = i),
                    icon: Icon(
                      i <= _score ? Icons.star : Icons.star_border,
                      color: i <= _score ? c.brand500 : c.inkFaint,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              key: const Key('rating.comment'),
              controller: _comment,
              maxLength: ratingCommentMax,
              maxLines: 3,
              minLines: 1,
              enabled: !_sending,
              decoration: InputDecoration(
                labelText: l.ratingCommentLabel,
                hintText: l.ratingCommentHint,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s2),
              InlineError(_error!, key: const Key('rating.error')),
            ],
            const SizedBox(height: AppSpacing.s4),
            PrimaryButton(
              key: const Key('rating.submit'),
              label: l.ratingSubmit,
              loading: _sending,
              onPressed: _score == 0 ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.s2),
            TextButton(
              key: const Key('rating.skip'),
              onPressed: _sending
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: Text(l.ratingSkip),
            ),
          ],
        ),
      ),
    );
  }
}
