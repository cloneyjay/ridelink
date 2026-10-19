import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_text_styles.dart';
import '../auth_validators.dart';

/// Scrollable, padded body shared by every auth screen.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.showBack = false,
  });

  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.screenPadding,
            vertical: AppSpacing.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Logo tile, product name and tagline (wireframe screen 1).
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      children: [
        Container(
          width: AppSpacing.s16,
          height: AppSpacing.s16,
          decoration: BoxDecoration(
            color: c.brand500,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: context.shadows.brand,
          ),
          child: Icon(Symbols.two_wheeler, color: c.inkOnBrand),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(l.appName, style: AppTextStyles.displayXl.copyWith(color: c.ink)),
        const SizedBox(height: AppSpacing.s1),
        Text(
          l.appTagline,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}

class ScreenHeading extends StatelessWidget {
  const ScreenHeading({super.key, required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.displayLg.copyWith(color: c.ink)),
        if (body != null) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(body!, style: AppTextStyles.body.copyWith(color: c.inkMuted)),
        ],
      ],
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      key: const Key('auth.error'),
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

class InfoBanner extends StatelessWidget {
  const InfoBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(message, style: AppTextStyles.bodySm.copyWith(color: c.ink)),
    );
  }
}

/// Primary CTA that swaps its label for a spinner while [loading].
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
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
}

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller, this.enabled = true});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextFormField(
      key: const Key('auth.email'),
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: l.emailLabel),
      validator: (v) => validateEmail(v, l),
    );
  }
}

/// Password with show/hide; [showLengthHint] adds the live 15-character hint.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.showLengthHint = false,
    this.isNewPassword = false,
    this.onSubmitted,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final bool showLengthHint;
  final bool isNewPassword;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    if (widget.showLengthHint) widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final met = passwordLongEnough(widget.controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('auth.password'),
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscured,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: [
            widget.isNewPassword
                ? AutofillHints.newPassword
                : AutofillHints.password,
          ],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: IconButton(
              key: const Key('auth.password.toggle'),
              tooltip: _obscured ? l.showPassword : l.hidePassword,
              icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
              color: c.inkMuted,
              onPressed: () => setState(() => _obscured = !_obscured),
            ),
          ),
          validator: widget.validator,
        ),
        if (widget.showLengthHint) ...[
          const SizedBox(height: AppSpacing.s1),
          Row(
            key: const Key('auth.password.hint'),
            children: [
              Icon(
                met ? Icons.check_circle : Icons.radio_button_unchecked,
                size: AppSpacing.s4,
                color: met ? c.statusSuccess : c.inkFaint,
              ),
              const SizedBox(width: AppSpacing.s1),
              Text(
                l.passwordHint,
                style: AppTextStyles.bodySm.copyWith(
                  color: met ? c.statusSuccess : c.inkMuted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Digits only, max 6; pasting "123 456" or "123-456" keeps the digits.
class CodeField extends StatelessWidget {
  const CodeField({
    super.key,
    required this.controller,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextFormField(
      key: const Key('auth.code'),
      controller: controller,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      textAlign: TextAlign.center,
      style: AppTextStyles.displaySm.copyWith(color: context.colors.ink),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(labelText: l.codeLabel),
      validator: (v) => validateCode(v, l),
      onChanged: (v) {
        if (v.length == 6) onCompleted();
      },
    );
  }
}

/// "Resend code" that locks for [cooldown] after each send (server allows 1/min).
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({
    super.key,
    required this.onResend,
    this.startLocked = true,
    this.cooldown = const Duration(seconds: 60),
  });

  /// Returns true when a code was sent, which restarts the cooldown.
  final Future<bool> Function() onResend;
  final bool startLocked;
  final Duration cooldown;

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _timer;
  int _remaining = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.startLocked) _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _remaining = widget.cooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    final sent = await widget.onResend();
    if (!mounted) return;
    setState(() => _sending = false);
    if (sent) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locked = _remaining > 0;
    return TextButton(
      key: const Key('auth.resend'),
      onPressed: locked || _sending ? null : _resend,
      child: Text(locked ? l.resendIn(_remaining) : l.resendCode),
    );
  }
}

/// A row like "New to RideLink?  Create an account".
class PromptLink extends StatelessWidget {
  const PromptLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onPressed,
    this.actionKey,
  });

  final String prompt;
  final String action;
  final VoidCallback onPressed;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: AppTextStyles.bodySm.copyWith(color: context.colors.inkMuted),
        ),
        TextButton(key: actionKey, onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}
