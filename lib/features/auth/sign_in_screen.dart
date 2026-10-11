import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'auth_errors.dart';
import 'auth_form_state.dart';
import 'auth_validators.dart';
import 'google_auth.dart';
import 'widgets/auth_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with AuthFormState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _googleBusy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() {
    final email = _email.text.trim();
    return submit(
      () async {
        final session = await ref
            .read(authApiProvider)
            .signIn(email: email, password: _password.text);
        await ref.read(sessionManagerProvider).setSession(session);
      },
      onApiError: (e) async {
        if (!e.isEmailNotConfirmed) return false;
        if (mounted) {
          context.push(AppRoutes.verifyEmailFor(email, codeSent: false));
        }
        return true;
      },
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_googleBusy || busy) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _googleBusy = true;
      error = null;
    });
    try {
      final credential = await ref.read(googleAuthProvider).signIn();
      if (credential == null) return;
      await submit(
        () async {
          final session = await ref
              .read(authApiProvider)
              .signInWithGoogle(
                idToken: credential.idToken,
                rawNonce: credential.rawNonce,
              );
          await ref.read(sessionManagerProvider).setSession(session);
        },
        validate: false,
        on401: AuthUnauthorized.google,
      );
    } on GoogleAuthFailure {
      if (mounted) setState(() => error = l.errorGoogleFailed);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _joinAsRider() {
    ref.read(riderIntentProvider).set();
    context.push(AppRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final googleConfigured = ref.watch(googleAuthProvider).isConfigured;

    return AuthScaffold(
      key: const Key('screen.auth'),
      children: [
        const SizedBox(height: AppSpacing.s4),
        const BrandHeader(),
        const SizedBox(height: AppSpacing.s10),
        Form(
          key: formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EmailField(controller: _email),
                const SizedBox(height: AppSpacing.s3),
                PasswordField(
                  controller: _password,
                  label: l.passwordLabel,
                  validator: (v) => validateExistingPassword(v, l),
                  onSubmitted: _signIn,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('auth.forgot'),
            onPressed: () => context.push(AppRoutes.forgotPassword),
            child: Text(l.forgotPasswordLink),
          ),
        ),
        if (error != null) ...[
          ErrorBanner(error!),
          const SizedBox(height: AppSpacing.s3),
        ],
        SubmitButton(
          key: const Key('auth.submit'),
          label: l.signInButton,
          loading: busy && !_googleBusy,
          onPressed: _signIn,
        ),
        if (googleConfigured) ...[
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
                child: Text(
                  l.orDivider,
                  style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          OutlinedButton(
            key: const Key('auth.google'),
            onPressed: _googleBusy ? null : _signInWithGoogle,
            child: Text(l.continueWithGoogle),
          ),
        ],
        const SizedBox(height: AppSpacing.s4),
        PromptLink(
          prompt: l.noAccountPrompt,
          action: l.createAccountLink,
          actionKey: const Key('auth.toSignUp'),
          onPressed: () => context.push(AppRoutes.signUp),
        ),
        const SizedBox(height: AppSpacing.s8),
        const Divider(),
        const SizedBox(height: AppSpacing.s3),
        Text(
          l.riderPrompt,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
        ),
        TextButton(
          key: const Key('auth.joinRider'),
          onPressed: _joinAsRider,
          child: Text(l.riderJoinLink),
        ),
      ],
    );
  }
}
