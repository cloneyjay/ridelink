import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/widgets/booking_widgets.dart';
import '../common/confirm_dialog.dart';
import '../rider/widgets/rider_offer_watcher.dart';
import 'data/payment_models.dart';
import 'payment_validation.dart';
import 'payment_widgets.dart';

/// Rider: how payers can pay them directly. Cash is always on; M-Pesa Till, Pochi la Biashara
/// and Send Money are optional (at most one of each).
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  Map<PayMethod, PaymentMethod>? _methods;
  bool _failed = false;
  PayMethod? _removing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _methods = null;
      _failed = false;
    });
    try {
      final list = await ref.read(riderRepositoryProvider).paymentMethods();
      if (!mounted) return;
      setState(() => _methods = {for (final m in list) m.type: m});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _edit(PayMethod type) async {
    final l = AppLocalizations.of(context);
    final saved = await showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppLayout.sheetTopRadius),
        ),
      ),
      builder: (_) => _MethodSheet(type: type, current: _methods?[type]),
    );
    if (saved == null || !mounted) return;
    setState(() => _methods = {...?_methods, saved.type: saved});
    showSnack(
      context,
      l.paymentMethodSaved,
      key: const Key('payMethods.saved'),
    );
  }

  Future<void> _remove(PayMethod type) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      keyPrefix: 'payMethods.removeDialog',
      title: l.paymentMethodRemoveTitle(payMethodName(l, type)),
      body: l.paymentMethodRemoveBody,
      confirmLabel: l.paymentMethodRemove,
      cancelLabel: l.goBackButton,
    );
    if (!ok || !mounted) return;
    setState(() => _removing = type);
    try {
      await ref.read(riderRepositoryProvider).deletePaymentMethod(type);
      if (!mounted) return;
      setState(() {
        _removing = null;
        _methods = {...?_methods}..remove(type);
      });
      showSnack(
        context,
        l.paymentMethodRemoved,
        key: const Key('payMethods.removed'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _removing = null);
      showSnack(
        context,
        apiErrorText(e, l, fallback: l.paymentMethodRemoveFailed),
        key: const Key('payMethods.removeFailed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final methods = _methods;
    return RiderOfferWatcher(
      child: Scaffold(
        key: const Key('screen.paymentMethods'),
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.riderHome),
          ),
          title: Text(l.paymentMethodsTitle),
        ),
        body: SafeArea(
          child: _failed
              ? MessageView(
                  key: const Key('payMethods.error'),
                  icon: Icons.wifi_off,
                  title: l.paymentMethodsLoadError,
                  actionLabel: l.retryButton,
                  actionKey: const Key('payMethods.retry'),
                  onAction: _load,
                )
              : methods == null
              ? const LoadingView()
              : ListView(
                  padding: const EdgeInsets.all(AppLayout.screenPadding),
                  children: [
                    NoteRow(l.paymentMethodsIntro),
                    const SizedBox(height: AppSpacing.s4),
                    _MethodTile(
                      key: const Key('payMethods.cash'),
                      method: PayMethod.cash,
                      trailing: InfoChip(
                        l.cashAlwaysAccepted,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    for (final type in PayMethod.mpesa) ...[
                      const SizedBox(height: AppSpacing.s3),
                      _MethodTile(
                        key: Key('payMethods.${type.wire}'),
                        method: type,
                        details: methods[type],
                        busy: _removing == type,
                        onEdit: () => _edit(type),
                        onRemove: () => _remove(type),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      l.paymentMethodsFootnote,
                      style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    super.key,
    required this.method,
    this.details,
    this.trailing,
    this.busy = false,
    this.onEdit,
    this.onRemove,
  });

  final PayMethod method;
  final PaymentMethod? details;
  final Widget? trailing;
  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final d = details;
    final key = 'payMethods.${method.wire}';
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(payMethodIcon(method), color: c.inkMuted),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  payMethodName(l, method),
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
              ),
              ?trailing,
            ],
          ),
          if (method.isMpesa) ...[
            const SizedBox(height: AppSpacing.s2),
            if (d == null)
              Text(
                l.paymentMethodNotAdded,
                style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
              )
            else ...[
              Text(
                d.number,
                key: Key('$key.number'),
                style: AppTextStyles.bodyLg.copyWith(color: c.ink),
              ),
              Text(
                l.nameInMpesa(d.accountName),
                key: Key('$key.name'),
                style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
              ),
            ],
            const SizedBox(height: AppSpacing.s3),
            if (d == null)
              OutlinedButton.icon(
                key: Key('$key.add'),
                onPressed: onEdit,
                icon: const Icon(Icons.add),
                label: Text(l.paymentMethodAdd),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: Key('$key.edit'),
                      onPressed: busy ? null : onEdit,
                      child: Text(l.paymentMethodEdit),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: TextButton(
                      key: Key('$key.remove'),
                      onPressed: busy ? null : onRemove,
                      child: busy
                          ? SizedBox.square(
                              dimension: AppSpacing.s5,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.brand500,
                              ),
                            )
                          : Text(l.paymentMethodRemove),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// Add or edit one M-Pesa method: number + "Name shown in M-Pesa". Pops the saved method.
class _MethodSheet extends ConsumerStatefulWidget {
  const _MethodSheet({required this.type, this.current});

  final PayMethod type;
  final PaymentMethod? current;

  @override
  ConsumerState<_MethodSheet> createState() => _MethodSheetState();
}

class _MethodSheetState extends ConsumerState<_MethodSheet> {
  late final _number = TextEditingController(text: widget.current?.number);
  late final _name = TextEditingController(text: widget.current?.accountName);
  PaymentFieldError? _numberError;
  PaymentFieldError? _nameError;
  String? _serverError;
  bool _saving = false;

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  String? _text(AppLocalizations l, PaymentFieldError? e) => switch (e) {
    null => null,
    PaymentFieldError.required => l.settingsRequired,
    PaymentFieldError.tillInvalid => l.tillNumberInvalid,
    PaymentFieldError.phoneInvalid => l.mpesaPhoneInvalid,
    PaymentFieldError.nameInvalid => l.mpesaNameInvalid,
  };

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final input = validateMethodInput(widget.type, _number.text, _name.text);
    setState(() {
      _numberError = input.numberError;
      _nameError = input.nameError;
      _serverError = null;
    });
    if (input.number == null || input.accountName == null) return;
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(riderRepositoryProvider)
          .savePaymentMethod(
            widget.type,
            number: input.number!,
            accountName: input.accountName!,
          );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = apiErrorText(e, l, fallback: l.settingsSaveFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final till = widget.type == PayMethod.mpesaTill;
    return Padding(
      key: const Key('payMethods.sheet'),
      padding: EdgeInsets.only(
        left: AppLayout.screenPadding,
        right: AppLayout.screenPadding,
        top: AppSpacing.s6,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.s6,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              payMethodName(l, widget.type),
              style: AppTextStyles.displaySm.copyWith(color: c.ink),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              key: const Key('payMethods.number'),
              controller: _number,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  till ? RegExp('[0-9]') : RegExp(r'[0-9+ \-]'),
                ),
              ],
              decoration: InputDecoration(
                labelText: till ? l.tillNumberLabel : l.mpesaPhoneLabel,
                errorText: _text(l, _numberError),
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              key: const Key('payMethods.name'),
              controller: _name,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.mpesaNameLabel,
                helperText: l.mpesaNameHelp,
                helperMaxLines: 2,
                errorText: _text(l, _nameError),
                errorMaxLines: 2,
              ),
            ),
            if (_serverError != null) ...[
              const SizedBox(height: AppSpacing.s3),
              InlineError(
                _serverError!,
                key: const Key('payMethods.saveError'),
              ),
            ],
            const SizedBox(height: AppSpacing.s6),
            PrimaryButton(
              key: const Key('payMethods.save'),
              label: l.settingsSave,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
