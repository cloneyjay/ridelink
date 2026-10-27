import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_messages.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/booking_labels.dart';
import '../booking/widgets/booking_widgets.dart';
import '../orders/order_providers.dart';
import '../payments/data/payment_models.dart';
import '../payments/pay_rider_card.dart';
import '../payments/payment_validation.dart';
import '../payments/payment_widgets.dart';
import '../rider/rider_labels.dart' show formatDateTime;
import 'data/restriction_models.dart';
import 'restriction_providers.dart';

/// Sender with an open balance (D5 + amendments): what is owed, to whom, every way to pay the
/// rider, "Waiting for your rider to confirm", and "I've paid" (rider asked to confirm, review
/// case opened). The balance clears when the rider confirms or staff settle it.
class SettleBalanceScreen extends ConsumerWidget {
  const SettleBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final balances = ref.watch(outstandingBalancesProvider);
    Future<void> refresh() => ref.refresh(outstandingBalancesProvider.future);

    Widget body;
    if (balances.hasError && !balances.hasValue) {
      body = MessageView(
        key: const Key('balance.error'),
        icon: Icons.wifi_off,
        title: l.balanceLoadFailed,
        actionLabel: l.retryButton,
        actionKey: const Key('balance.retry'),
        onAction: () => ref.invalidate(outstandingBalancesProvider),
      );
    } else if (!balances.hasValue) {
      body = const LoadingView();
    } else if (balances.value!.isEmpty) {
      body = MessageView(
        key: const Key('balance.settled'),
        icon: Icons.check_circle_outline,
        title: l.balanceSettledTitle,
        body: l.balanceSettledBody,
        actionLabel: l.backToHomeButton,
        actionKey: const Key('balance.home'),
        onAction: () => context.go(AppRoutes.home),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [
            NoteRow(l.settleBalanceIntro, key: const Key('balance.intro')),
            for (final b in balances.value!) ...[
              const SizedBox(height: AppSpacing.s4),
              _BalanceCard(key: ValueKey(b.orderId), balance: b),
            ],
          ],
        ),
      );
    }
    return Scaffold(
      key: const Key('screen.settleBalance'),
      appBar: AppBar(title: Text(l.settleBalanceTitle)),
      body: SafeArea(child: body),
    );
  }
}

class _BalanceCard extends ConsumerStatefulWidget {
  const _BalanceCard({super.key, required this.balance});

  final OutstandingBalance balance;

  @override
  ConsumerState<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<_BalanceCard> {
  bool _claiming = false;
  bool _claimed = false;
  bool _busy = false;
  PayMethod _method = PayMethod.cash;
  final _code = TextEditingController();
  final _note = TextEditingController();
  String? _codeError;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _note.dispose();
    super.dispose();
  }

  PayMethod get _selected =>
      widget.balance.choices.contains(_method) ? _method : PayMethod.cash;

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final method = _selected;
    final check = mpesaCodeFor(method, _code.text);
    if (!check.valid) {
      setState(() => _codeError = l.mpesaCodeInvalid);
      return;
    }
    final note = method == PayMethod.cash && _note.text.trim().isNotEmpty
        ? _note.text.trim()
        : null;
    setState(() {
      _codeError = null;
      _error = null;
      _busy = true;
    });
    try {
      await ref
          .read(restrictionsRepositoryProvider)
          .claimPaid(
            widget.balance.orderId,
            PaidClaim(method: method, mpesaCode: check.code, note: note),
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _claimed = true;
        _claiming = false;
      });
      ref.invalidate(outstandingBalancesProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = apiErrorText(e, l, fallback: l.iPaidFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final b = widget.balance;
    final order = ref.watch(orderDetailsProvider(b.orderId)).value?.order;
    final prefix = 'balance.${b.orderId}';
    final claimed = _claimed || b.claimed;
    final canClaim = !_claimed && b.canClaim;
    return SurfaceCard(
      key: Key(prefix),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            b.riderFirstName.isEmpty
                ? l.balanceOwedToRider
                : l.balanceOwedTo(b.riderFirstName),
            style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
          ),
          Text(
            formatKes(b.amount),
            key: Key('$prefix.amount'),
            style: AppTextStyles.displayLg.copyWith(color: c.ink),
          ),
          const SizedBox(height: AppSpacing.s3),
          InkWell(
            key: Key('$prefix.order'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => context.push(AppRoutes.orderDetailFor(b.orderId)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppLayout.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                child: Row(
                  children: [
                    Icon(
                      order == null
                          ? Icons.receipt_long_outlined
                          : serviceIcon(order.serviceType),
                      color: order == null
                          ? c.inkMuted
                          : serviceAccent(c, order.serviceType),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order == null || order.dropoffAddress.isEmpty
                                ? l.balanceViewOrder
                                : order.dropoffAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLg.copyWith(color: c.ink),
                          ),
                          if (order?.createdAt != null)
                            Text(
                              formatDateTime(l, order!.createdAt!),
                              style: AppTextStyles.bodySm.copyWith(
                                color: c.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: c.inkFaint),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          if (b.cash) ...[
            PayOptionTile(method: PayMethod.cash, keyPrefix: prefix),
            const SizedBox(height: AppSpacing.s2),
          ],
          for (final m in b.methods) ...[
            PayOptionTile(method: m.type, details: m, keyPrefix: prefix),
            const SizedBox(height: AppSpacing.s2),
          ],
          const SizedBox(height: AppSpacing.s2),
          Row(
            key: Key('$prefix.waiting'),
            children: [
              Icon(Icons.hourglass_top, color: c.statusWarning),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  claimed ? l.iPaidSent : l.waitingForRiderConfirm,
                  key: claimed ? Key('$prefix.claimed') : null,
                  style: AppTextStyles.body.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
          if (canClaim && !_claiming) ...[
            const SizedBox(height: AppSpacing.s3),
            OutlinedButton(
              key: Key('$prefix.iPaid'),
              onPressed: () => setState(() => _claiming = true),
              child: Text(l.iPaidButton),
            ),
          ],
          if (canClaim && _claiming) ..._claimForm(l, c, prefix),
        ],
      ),
    );
  }

  List<Widget> _claimForm(AppLocalizations l, AppColors c, String prefix) {
    final selected = _selected;
    return [
      const SizedBox(height: AppSpacing.s4),
      Text(l.iPaidTitle, style: AppTextStyles.labelLg.copyWith(color: c.ink)),
      const SizedBox(height: AppSpacing.s2),
      for (final m in widget.balance.choices) ...[
        ChoiceRow(
          key: Key('$prefix.claim.${m.wire}'),
          selected: m == selected,
          title: payMethodName(l, m),
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
      if (selected.isMpesa)
        MpesaCodeField(
          key: Key('$prefix.claimCode'),
          controller: _code,
          errorText: _codeError,
          enabled: !_busy,
        )
      else
        TextField(
          key: Key('$prefix.claimNote'),
          controller: _note,
          enabled: !_busy,
          maxLength: cashNoteMaxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l.cashNoteLabel,
            helperText: l.cashNoteHelp,
          ),
        ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.s3),
        InlineError(_error!, key: Key('$prefix.claimError')),
      ],
      const SizedBox(height: AppSpacing.s3),
      PrimaryButton(
        key: Key('$prefix.claimSubmit'),
        label: l.iPaidSubmit,
        loading: _busy,
        onPressed: _submit,
      ),
    ];
  }
}
