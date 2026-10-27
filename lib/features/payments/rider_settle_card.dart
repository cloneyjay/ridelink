import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_messages.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/widgets/booking_widgets.dart';
import '../common/confirm_dialog.dart';
import '../orders/order_providers.dart';
import 'data/payment_models.dart';
import 'payment_validation.dart';
import 'payment_widgets.dart';

/// Rider, after the drop-off on an `unresolved` order (no ruling yet) or a `closed_unpaid` order
/// with an open balance: "Payment received" with the method and optional M-Pesa code. Completes
/// the order (and settles the balance) through POST /orders/{id}/payment/received.
class RiderSettleCard extends ConsumerStatefulWidget {
  const RiderSettleCard({
    super.key,
    required this.orderId,
    required this.body,
    required this.onConfirm,
    this.onForgive,
    this.keyPrefix = 'settle',
  });

  final String orderId;
  final String body;

  /// Records the payment; throws on failure (shown inline).
  final Future<void> Function(PayMethod method, String? mpesaCode) onConfirm;

  /// Set while the order has an open balance: "Forgive balance" (after a confirmation).
  final Future<void> Function()? onForgive;

  /// Keys: `<keyPrefix>`, `.method.<type>`, `.code`, `.submit`, `.error`.
  final String keyPrefix;

  @override
  ConsumerState<RiderSettleCard> createState() => _RiderSettleCardState();
}

class _RiderSettleCardState extends ConsumerState<RiderSettleCard> {
  PayMethod _method = PayMethod.cash;
  final _code = TextEditingController();
  String? _codeError;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  PayMethod _selected(OrderPayment? p) {
    final choices = p?.choices ?? const [PayMethod.cash];
    return choices.contains(_method) ? _method : PayMethod.cash;
  }

  Future<void> _forgive() async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      keyPrefix: '${widget.keyPrefix}.forgiveDialog',
      title: l.forgiveBalanceTitle,
      body: l.forgiveBalanceBody,
      confirmLabel: l.forgiveBalanceConfirm,
      cancelLabel: l.goBackButton,
    );
    if (!ok || !mounted) return;
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await widget.onForgive!();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = apiErrorText(e, l, fallback: l.jobActionFailed),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final method = _selected(
      ref.read(orderPaymentProvider(widget.orderId)).value,
    );
    final check = mpesaCodeFor(method, _code.text);
    if (!check.valid) {
      setState(() => _codeError = l.mpesaCodeInvalid);
      return;
    }
    setState(() {
      _codeError = null;
      _error = null;
      _busy = true;
    });
    try {
      await widget.onConfirm(method, check.code);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = apiErrorText(e, l, fallback: l.jobActionFailed),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final p = widget.keyPrefix;
    final payment = ref.watch(orderPaymentProvider(widget.orderId));
    final data = payment.value;
    final choices = data?.choices ?? const [PayMethod.cash];
    final selected = _selected(data);
    final numbers = {
      for (final m in data?.methods ?? const <PaymentMethod>[]) m.type: m,
    };
    return SurfaceCard(
      key: Key(p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.riderSettleTitle,
            style: AppTextStyles.displaySm.copyWith(color: c.ink),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(widget.body, style: AppTextStyles.body.copyWith(color: c.ink)),
          const SizedBox(height: AppSpacing.s4),
          Text(
            l.paymentHowPaidLabel,
            style: AppTextStyles.labelLg.copyWith(color: c.ink),
          ),
          const SizedBox(height: AppSpacing.s2),
          for (final m in choices) ...[
            ChoiceRow(
              key: Key('$p.method.${m.wire}'),
              selected: m == selected,
              title: payMethodName(l, m),
              subtitle: numbers[m] == null
                  ? null
                  : payNumberFor(numbers[m]!).shown,
              icon: payMethodIcon(m),
              onTap: _busy
                  ? null
                  : () => setState(() {
                      _method = m;
                      _codeError = null;
                    }),
            ),
            const SizedBox(height: AppSpacing.s2),
          ],
          if (payment.hasError && !payment.isLoading) ...[
            InlineError(
              l.paymentMethodsLoadFailed,
              key: Key('$p.methodsError'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('$p.methodsRetry'),
                onPressed: () =>
                    ref.invalidate(orderPaymentProvider(widget.orderId)),
                child: Text(l.retryButton),
              ),
            ),
          ],
          if (selected.isMpesa) ...[
            const SizedBox(height: AppSpacing.s2),
            MpesaCodeField(
              key: Key('$p.code'),
              controller: _code,
              errorText: _codeError,
              enabled: !_busy,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.s3),
            InlineError(_error!, key: Key('$p.error')),
          ],
          const SizedBox(height: AppSpacing.s3),
          PrimaryButton(
            key: Key('$p.submit'),
            label: l.paymentReceivedButton,
            loading: _busy,
            onPressed: _submit,
          ),
          if (widget.onForgive != null) ...[
            const SizedBox(height: AppSpacing.s2),
            TextButton(
              key: Key('$p.forgive'),
              onPressed: _busy ? null : _forgive,
              child: Text(l.forgiveBalanceButton),
            ),
          ],
        ],
      ),
    );
  }
}
