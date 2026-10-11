import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_dimensions.dart';
import 'auth_errors.dart';
import 'auth_form_state.dart';
import 'widgets/auth_widgets.dart';

/// Confirms a new account's email with the 6-digit code.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.codeSent,
  });

  final String email;

  /// False when arriving from a sign-in on an unconfirmed email: resend is open at once.
  final bool codeSent;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with AuthFormState<VerifyEmailScreen> {
  final _code = TextEditingController();
  String? _info;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() => submit(() async {
    final session = await ref
        .read(authApiProvider)
        .verifySignup(email: widget.email, code: _code.text);
    await ref.read(sessionManagerProvider).setSession(session);
  }, on401: AuthUnauthorized.invalidCode);

  Future<bool> _resend() async {
    final l = AppLocalizations.of(context);
    setState(() {
      error = null;
      _info = null;
    });
    try {
      await ref.read(authApiProvider).resendSignup(widget.email);
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
      key: const Key('screen.verifyEmail'),
      showBack: true,
      children: [
        ScreenHeading(
          title: l.verifyTitle,
          body: widget.codeSent
              ? l.verifySentTo(widget.email)
              : l.verifyNotConfirmed(widget.email),
        ),
        const SizedBox(height: AppSpacing.s6),
        Form(
          key: formKey,
          child: CodeField(controller: _code, onCompleted: _verify),
        ),
        const SizedBox(height: AppSpacing.s4),
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
          label: l.verifyButton,
          loading: busy,
          onPressed: _verify,
        ),
        const SizedBox(height: AppSpacing.s2),
        ResendCodeButton(onResend: _resend, startLocked: widget.codeSent),
      ],
    );
  }
}
