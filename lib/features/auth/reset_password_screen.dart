import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_dimensions.dart';
import 'auth_errors.dart';
import 'auth_form_state.dart';
import 'auth_validators.dart';
import 'widgets/auth_widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with AuthFormState<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _info;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _reset() => submit(() async {
    final session = await ref
        .read(authApiProvider)
        .resetPassword(
          email: widget.email,
          code: _code.text,
          newPassword: _password.text,
        );
    await ref.read(sessionManagerProvider).setSession(session);
  }, on401: AuthUnauthorized.invalidCode);

  Future<bool> _resend() async {
    final l = AppLocalizations.of(context);
    setState(() {
      error = null;
      _info = null;
    });
    try {
      await ref.read(authApiProvider).forgotPassword(widget.email);
      if (mounted) setState(() => _info = l.codeResent);
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => error = authErrorMessage(e, l));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      key: const Key('screen.resetPassword'),
      showBack: true,
      children: [
        ScreenHeading(title: l.resetTitle, body: l.resetSentTo(widget.email)),
        const SizedBox(height: AppSpacing.s6),
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CodeField(
                controller: _code,
                onCompleted: _passwordFocus.requestFocus,
              ),
              const SizedBox(height: AppSpacing.s3),
              PasswordField(
                controller: _password,
                focusNode: _passwordFocus,
                label: l.newPasswordLabel,
                validator: (v) => validateNewPassword(v, l),
                showLengthHint: true,
                isNewPassword: true,
                onSubmitted: _reset,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        if (_info != null) ...[
          InfoBanner(_info!),
          const SizedBox(height: AppSpacing.s3),
        ],
        if (error != null) ...[
          ErrorBanner(error!),
          const SizedBox(height: AppSpacing.s3),
        ],
        SubmitButton(
          key: const Key('auth.submit'),
          label: l.resetButton,
          loading: busy,
          onPressed: _reset,
        ),
        const SizedBox(height: AppSpacing.s2),
        ResendCodeButton(onResend: _resend),
      ],
    );
  }
}
