import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/widgets/booking_widgets.dart';
import '../rider/rider_labels.dart' show formatDate;
import 'data/restriction_models.dart';
import 'data/restrictions_repository.dart';
import 'restriction_labels.dart';
import 'restriction_providers.dart';

/// Both roles (D6 + amendments): the suspension or intended suspension, the one-time appeal or
/// response, and account standing (warnings with a one-time dispute each).
class AccountStatusScreen extends ConsumerWidget {
  const AccountStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(accountStatusProvider);
    Widget body;
    if (status.hasError && !status.hasValue) {
      body = MessageView(
        key: const Key('account.error'),
        icon: Icons.wifi_off,
        title: l.accountStatusLoadFailed,
        actionLabel: l.retryButton,
        actionKey: const Key('account.retry'),
        onAction: () => ref.invalidate(accountStatusProvider),
      );
    } else if (!status.hasValue) {
      body = const LoadingView();
    } else {
      final s = status.value!;
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(accountStatusProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [
            switch (s.effectivePhase) {
              SuspensionPhase.active => SuspensionCard(status: s),
              SuspensionPhase.intended => SuspensionCard(status: s),
              SuspensionPhase.none => _ActiveCard(appeal: s.appeal),
            },
            if (s.effectivePhase == SuspensionPhase.active) ...[
              const SizedBox(height: AppSpacing.s4),
              _AppealSection(appeal: s.appeal),
            ],
            if (s.intended) ...[
              const SizedBox(height: AppSpacing.s4),
              _ResponseSection(status: s),
            ],
            const SizedBox(height: AppSpacing.s6),
            _StandingSection(strikes: s.strikes),
          ],
        ),
      );
    }
    return Scaffold(
      key: const Key('screen.accountStatus'),
      appBar: AppBar(title: Text(l.accountStatusTitle)),
      body: SafeArea(child: body),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.appeal});

  final AppealState appeal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return SurfaceCard(
      key: const Key('account.active'),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: c.statusSuccess),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.accountNotSuspended,
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
                if (appeal.status == AppealStatus.lifted)
                  Text(
                    l.appealLifted,
                    style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The suspension notice: title by phase, then the summary sentence(s).
class SuspensionCard extends StatelessWidget {
  const SuspensionCard({super.key, required this.status, this.action});

  final AccountStatus status;

  /// Optional button under the text (e.g. "View details" on banners).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final title = status.intended
        ? l.suspensionIntendedTitle
        : status.onHold
        ? l.accountOnHoldTitle
        : l.accountSuspendedTitle;
    return Container(
      key: Key(status.intended ? 'account.intended' : 'account.suspended'),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: c.statusErrorTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status.intended ? Icons.report_outlined : Icons.block,
            color: c.statusError,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  suspensionSummary(l, status),
                  key: const Key('account.summary'),
                  style: AppTextStyles.body.copyWith(color: c.ink),
                ),
                if (status.suspended && status.appeal.canAppeal) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    l.accountSuspendedCanAppeal,
                    key: const Key('account.canAppeal'),
                    style: AppTextStyles.body.copyWith(color: c.ink),
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.s2),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A one-time message form (appeal, response, dispute): validates non-empty, sends, then
/// re-reads the account status. A 409 means it was already sent.
class _MessageForm extends ConsumerStatefulWidget {
  const _MessageForm({
    required this.keyPrefix,
    required this.label,
    required this.submitLabel,
    required this.requiredText,
    required this.failedText,
    required this.send,
  });

  final String keyPrefix;
  final String label;
  final String submitLabel;
  final String requiredText;
  final String failedText;
  final Future<void> Function(String message) send;

  @override
  ConsumerState<_MessageForm> createState() => _MessageFormState();
}

class _MessageFormState extends ConsumerState<_MessageForm> {
  final _message = TextEditingController();
  String? _fieldError;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final text = _message.text.trim();
    if (text.isEmpty) {
      setState(() => _fieldError = widget.requiredText);
      return;
    }
    setState(() {
      _fieldError = null;
      _error = null;
      _busy = true;
    });
    try {
      await widget.send(text);
      if (!mounted) return;
      ref.invalidate(accountStatusProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isConflict) ref.invalidate(accountStatusProvider);
      setState(() => _error = apiErrorText(e, l, fallback: widget.failedText));
    } catch (_) {
      if (mounted) setState(() => _error = widget.failedText);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.keyPrefix;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: Key('$p.message'),
          controller: _message,
          enabled: !_busy,
          minLines: 3,
          maxLines: 8,
          maxLength: appealMaxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: widget.label,
            alignLabelWithHint: true,
            errorText: _fieldError,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s3),
          InlineError(_error!, key: Key('$p.error')),
        ],
        const SizedBox(height: AppSpacing.s3),
        PrimaryButton(
          key: Key('$p.submit'),
          label: widget.submitLabel,
          loading: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    this.note,
    required this.child,
  });

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.labelLg.copyWith(color: c.ink)),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(
              note!,
              style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.s3),
          child,
        ],
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.body.copyWith(color: context.colors.ink));
}

class _AppealSection extends ConsumerWidget {
  const _AppealSection({required this.appeal});

  final AppealState appeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final statusText = switch (appeal.status) {
      AppealStatus.pending => l.appealPending,
      AppealStatus.upheld => l.appealUpheld,
      AppealStatus.lifted => l.appealLifted,
      AppealStatus.none => null,
    };
    if (statusText != null) {
      return _Section(
        key: Key('account.appeal.${appeal.status.wire}'),
        title: l.appealTitle,
        child: _StatusText(statusText),
      );
    }
    if (!appeal.canAppeal) return const SizedBox.shrink();
    return _Section(
      key: const Key('account.appealForm'),
      title: l.appealTitle,
      note: l.appealOnceNote,
      child: _MessageForm(
        keyPrefix: 'account.appeal',
        label: l.appealLabel,
        submitLabel: l.appealSubmit,
        requiredText: l.appealRequired,
        failedText: l.appealFailed,
        send: ref.read(restrictionsRepositoryProvider).appeal,
      ),
    );
  }
}

class _ResponseSection extends ConsumerWidget {
  const _ResponseSection({required this.status});

  final AccountStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (status.responseSent) {
      return _Section(
        key: const Key('account.responseSent'),
        title: l.suspensionResponseLabel,
        child: _StatusText(l.suspensionResponseSent),
      );
    }
    if (!status.canRespond) return const SizedBox.shrink();
    return _Section(
      key: const Key('account.responseForm'),
      title: l.suspensionResponseLabel,
      child: _MessageForm(
        keyPrefix: 'account.response',
        label: l.suspensionResponseLabel,
        submitLabel: l.suspensionResponseSubmit,
        requiredText: l.suspensionResponseRequired,
        failedText: l.suspensionResponseFailed,
        send: ref.read(restrictionsRepositoryProvider).respondToSuspension,
      ),
    );
  }
}

class _StandingSection extends StatelessWidget {
  const _StandingSection({required this.strikes});

  final List<Strike> strikes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Section(
      key: const Key('account.standing'),
      title: l.standingTitle,
      note: l.standingRule,
      child: strikes.isEmpty
          ? _StatusText(
              l.standingNoWarnings,
              key: const Key('account.noStrikes'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, s) in strikes.indexed) ...[
                  if (i > 0) const Divider(height: AppSpacing.s6),
                  _StrikeTile(strike: s),
                ],
              ],
            ),
    );
  }
}

class _StrikeTile extends ConsumerStatefulWidget {
  const _StrikeTile({required this.strike});

  final Strike strike;

  @override
  ConsumerState<_StrikeTile> createState() => _StrikeTileState();
}

class _StrikeTileState extends ConsumerState<_StrikeTile> {
  bool _disputing = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final s = widget.strike;
    final p = 'account.strike.${s.id}';
    final dates = [
      if (s.issuedAt != null) l.strikeIssuedOn(formatDate(l, s.issuedAt!)),
      if (s.expiresAt != null) l.strikeExpiresOn(formatDate(l, s.expiresAt!)),
    ].join(' · ');
    final disputeText = switch (s.dispute) {
      DisputeStatus.pending => l.disputePending,
      DisputeStatus.upheld => l.disputeUpheld,
      DisputeStatus.rejected => l.disputeRejected,
      DisputeStatus.none => null,
    };
    return Column(
      key: Key(p),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: c.statusWarning),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strikeReasonText(l, s.reason),
                    style: AppTextStyles.labelLg.copyWith(color: c.ink),
                  ),
                  if (dates.isNotEmpty)
                    Text(
                      dates,
                      key: Key('$p.dates'),
                      style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (s.orderId != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: Key('$p.order'),
              onPressed: () =>
                  context.push(AppRoutes.orderDetailFor(s.orderId!)),
              child: Text(l.balanceViewOrder),
            ),
          ),
        if (disputeText != null) ...[
          const SizedBox(height: AppSpacing.s1),
          Text(
            disputeText,
            key: Key('$p.dispute.${s.dispute.wire}'),
            style: AppTextStyles.bodySm.copyWith(color: c.ink),
          ),
        ] else if (s.canDispute && !_disputing)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: Key('$p.disputeOpen'),
              onPressed: () => setState(() => _disputing = true),
              child: Text(l.disputeButton),
            ),
          )
        else if (s.canDispute) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            l.disputeOnceNote,
            style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s2),
          _MessageForm(
            keyPrefix: '$p.dispute',
            label: l.disputeLabel,
            submitLabel: l.disputeSubmit,
            requiredText: l.disputeRequired,
            failedText: l.disputeFailed,
            send: (m) =>
                ref.read(restrictionsRepositoryProvider).disputeStrike(s.id, m),
          ),
        ],
      ],
    );
  }
}
