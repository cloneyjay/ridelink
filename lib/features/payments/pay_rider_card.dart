import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/errors/error_messages.dart';
import '../../core/format/money.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/widgets/booking_widgets.dart';
import '../common/confirm_dialog.dart';
import '../orders/order_providers.dart';
import 'data/payment_models.dart';
import 'payment_widgets.dart';

/// Sender, while `payment_requested`: the amount and every way to pay the rider directly
/// (cash, plus the rider's M-Pesa methods snapshotted at acceptance). No "I've paid" button:
/// the rider confirms.
class PayRiderCard extends ConsumerWidget {
  const PayRiderCard({
    super.key,
    required this.orderId,
    this.amount,
    required this.onHidden,
  });

  final String orderId;

  /// The agreed price, shown until the payment view loads.
  final int? amount;

  /// The server hid the details (the order left `payment_requested`): reload the order.
  final VoidCallback onHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<OrderPayment>>(orderPaymentProvider(orderId), (
      _,
      next,
    ) {
      final e = next.error;
      if (e is ApiException && e.code == 'payment_details_hidden') onHidden();
    });
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final payment = ref.watch(orderPaymentProvider(orderId));
    final data = payment.value;
    final shown = data?.amount ?? amount;
    return Container(
      key: const Key('tracking.payNow'),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.payYourRiderTitle,
            style: AppTextStyles.displaySm.copyWith(color: c.ink),
          ),
          if (shown != null)
            Text(
              formatKes(shown),
              key: const Key('tracking.payAmount'),
              style: AppTextStyles.displayLg.copyWith(color: c.ink),
            ),
          const SizedBox(height: AppSpacing.s3),
          if (data == null || data.cash)
            const _PayOption(method: PayMethod.cash),
          for (final m in data?.methods ?? const <PaymentMethod>[]) ...[
            const SizedBox(height: AppSpacing.s2),
            _PayOption(method: m.type, details: m),
          ],
          if (payment.isLoading) ...[
            const SizedBox(height: AppSpacing.s3),
            LinearProgressIndicator(
              key: const Key('tracking.payLoading'),
              color: c.brand500,
              backgroundColor: c.surfaceRaised,
            ),
          ],
          if (payment.hasError && !payment.isLoading) ...[
            const SizedBox(height: AppSpacing.s3),
            InlineError(
              apiErrorText(
                payment.error!,
                l,
                fallback: l.paymentDetailsLoadFailed,
              ),
              key: const Key('tracking.payError'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('tracking.payRetry'),
                onPressed: () => ref.invalidate(orderPaymentProvider(orderId)),
                child: Text(l.retryButton),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({required this.method, this.details});

  final PayMethod method;
  final PaymentMethod? details;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final d = details;
    return Container(
      key: Key('tracking.pay.${method.wire}'),
      constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(payMethodIcon(method), color: c.inkMuted),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payMethodName(l, method),
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
                if (d != null) ...[
                  Text(
                    d.number,
                    key: Key('tracking.pay.${method.wire}.number'),
                    style: AppTextStyles.bodyLg.copyWith(color: c.ink),
                  ),
                  Text(
                    l.nameInMpesa(d.accountName),
                    style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          if (d != null)
            IconButton(
              key: Key('tracking.copy.${method.wire}'),
              tooltip: l.copyNumber,
              constraints: const BoxConstraints(
                minWidth: AppLayout.minTapTarget,
                minHeight: AppLayout.minTapTarget,
              ),
              icon: Icon(Icons.copy_outlined, color: c.brand700),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: d.number));
                if (context.mounted) {
                  showSnack(
                    context,
                    l.numberCopied,
                    key: const Key('tracking.copied'),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
