import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_dimensions.dart';
import '../legal/legal_widgets.dart';
import 'auth_form_state.dart';
import 'auth_validators.dart';
import 'widgets/auth_widgets.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with AuthFormState<SignUpScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agreed = false;
  String? _consentError;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (busy) return;
    final l = AppLocalizations.of(context);
    final formOk = formKey.currentState?.validate() ?? false;
    setState(
      () => _consentError = _agreed ? null : l.errCodeLegalAcceptanceRequired,
    );
    if (!formOk || !_agreed) return;
    final email = _email.text.trim();
    await submit(() async {
      final docs = await loadLegalDocs(ref);
      await ref
          .read(authApiProvider)
          .signUp(
            email: email,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            password: _password.text,
            acceptedTermsVersion: docs.terms.version,
            acceptedPrivacyVersion: docs.privacy.version,
          );
      if (mounted) {
        context.push(AppRoutes.verifyEmailFor(email, codeSent: true));
      }
    }, validate: false);
  }

  void _toSignIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final riderIntent = ref.watch(riderIntentProvider).active;

    return AuthScaffold(
      key: const Key('screen.signUp'),
      showBack: true,
      children: [
        ScreenHeading(
          title: l.signUpTitle,
          body: riderIntent ? l.signUpRiderNote : null,
        ),
        const SizedBox(height: AppSpacing.s6),
        Form(
          key: formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('auth.firstName'),
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l.firstNameLabel),
                  validator: (v) => validateFirstName(v, l),
                ),
                const SizedBox(height: AppSpacing.s3),
                TextFormField(
                  key: const Key('auth.lastName'),
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.familyName],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l.lastNameLabel),
                  validator: (v) => validateLastName(v, l),
                ),
                const SizedBox(height: AppSpacing.s3),
                EmailField(controller: _email),
                const SizedBox(height: AppSpacing.s3),
                PasswordField(
                  controller: _password,
                  label: l.passwordLabel,
                  validator: (v) => validateNewPassword(v, l),
                  showLengthHint: true,
                  isNewPassword: true,
                  onSubmitted: _signUp,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        LegalConsent(
          keyPrefix: 'signUp.legal',
          value: _agreed,
          errorText: _consentError,
          onChanged: (v) => setState(() {
            _agreed = v;
            if (v) _consentError = null;
          }),
        ),
        const SizedBox(height: AppSpacing.s4),
        if (error != null) ...[
          ErrorBanner(error!),
          const SizedBox(height: AppSpacing.s3),
        ],
        SubmitButton(
          key: const Key('auth.submit'),
          label: l.signUpButton,
          loading: busy,
          onPressed: _signUp,
        ),
        const SizedBox(height: AppSpacing.s4),
        PromptLink(
          prompt: l.haveAccountPrompt,
          action: l.signInLink,
          onPressed: _toSignIn,
        ),
      ],
    );
  }
}
