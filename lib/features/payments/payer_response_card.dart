import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../orders/order_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/data/booking_models.dart' show Payer;
import '../booking/widgets/booking_widgets.dart';
import 'data/payment_models.dart';
import 'payment_validation.dart';
import 'payment_widgets.dart';

/// Sender, after the rider reported the order as not paid (`unresolved`): "Did you pay?",
/// answered once (yes + method + optional code, or no). Shown only while GET /payment says
/// `payer_response: pending`; "answered" shows the thanks state; 422 (not a not-paid order)
/// shows nothing. A 409 on submit means it was already answered.
class PayerResponseCard extends ConsumerStatefulWidget {
  const PayerResponseCard({
    super.key,
    required this.orderId,
    this.payer = Payer.sender,
  });

  final String orderId;

  /// Receiver-paid deliveries ask whether it was paid, not whether the sender paid.
  final Payer payer;

  @override
  ConsumerState<PayerResponseCard> createState() => _PayerResponseCardState();
}

class _PayerResponseCardState extends ConsumerState<PayerResponseCard> {
  bool? _paid;
  PayMethod _method = PayMethod.cash;
  final _code = TextEditingController();
  String? _codeError;
  String? _error;
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _markDone() {
    setState(() {
      _busy = false;
      _done = true;
    });
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final paid = _paid;
    if (paid == null) return;
    final method = _selected(
      ref.read(orderPaymentProvider(widget.orderId)).value,
    );
    final check = paid
        ? mpesaCodeFor(method, _code.text)
        : (code: null, valid: true);
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
      await ref
          .read(bookingRepositoryProvider)
          .payerResponse(
            widget.orderId,
            paid
                ? PayerResponse.paid(method: method, mpesaCode: check.code)
                : const PayerResponse.notPaid(),
          );
      if (mounted) _markDone();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        _markDone();
        return;
      }
      setState(() {
        _busy = false;
        _error = apiErrorText(e, l, fallback: l.payerResponseFailed);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l.payerResponseFailed;
      });
    }
  }

  PayMethod _selected(OrderPayment? p) {
    final choices = p?.payerChoices ?? const [PayMethod.cash];
    return choices.contains(_method) ? _method : PayMethod.cash;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final payment = _done
        ? null
        : ref.watch(orderPaymentProvider(widget.orderId));
    final data = payment?.value;
    final error = payment?.error;
    if (!_done && data == null) {
      if (payment!.isLoading ||
          (error is ApiException && error.code == 'payment_details_hidden')) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineError(
            apiErrorText(error!, l),
            key: const Key('payer.loadError'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('payer.retry'),
              onPressed: () =>
                  ref.invalidate(orderPaymentProvider(widget.orderId)),
              child: Text(l.retryButton),
            ),
          ),
        ],
      );
    }
    final state = _done ? PayerResponseState.answered : data!.payerResponse;
    if (state == null) return const SizedBox.shrink();
    if (state == PayerResponseState.answered) {
      return Container(
        key: const Key('payer.thanks'),
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: c.statusSuccess),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                l.payerThanks,
                style: AppTextStyles.body.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
      );
    }
    void pick(VoidCallback change) {
      if (_busy) return;
      setState(() {
        change();
        _codeError = null;
      });
    }

    return Container(
      key: const Key('payer.prompt'),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: c.statusErrorTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.payer == Payer.receiver
                ? l.payerPromptTitleReceiver
                : l.payerPromptTitle,
            style: AppTextStyles.displaySm.copyWith(color: c.ink),
          ),
          const SizedBox(height: AppSpacing.s3),
          ChoiceRow(
            key: const Key('payer.yes'),
            selected: _paid == true,
            title: l.payerYes,
            onTap: () => pick(() => _paid = true),
          ),
          const SizedBox(height: AppSpacing.s2),
          ChoiceRow(
            key: const Key('payer.no'),
            selected: _paid == false,
            title: l.payerNo,
            onTap: () => pick(() => _paid = false),
          ),
          if (_paid == true) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              l.payerHowPaidLabel,
              style: AppTextStyles.labelLg.copyWith(color: c.ink),
            ),
            const SizedBox(height: AppSpacing.s2),
            for (final m in data!.payerChoices) ...[
              ChoiceRow(
                key: Key('payer.method.${m.wire}'),
                selected: m == _selected(data),
                title: payMethodName(l, m),
                icon: payMethodIcon(m),
                onTap: () => pick(() => _method = m),
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
            if (_selected(data).isMpesa)
              MpesaCodeField(
                key: const Key('payer.code'),
                controller: _code,
                errorText: _codeError,
                enabled: !_busy,
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.s3),
            InlineError(_error!, key: const Key('payer.error')),
          ],
          const SizedBox(height: AppSpacing.s4),
          PrimaryButton(
            key: const Key('payer.submit'),
            label: l.payerSubmit,
            loading: _busy,
            onPressed: _paid == null ? null : _submit,
          ),
        ],
      ),
    );
  }
}
