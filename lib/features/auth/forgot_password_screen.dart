import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_dimensions.dart';
import 'auth_form_state.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with AuthFormState<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendCode() {
    final email = _email.text.trim();
    return submit(() async {
      await ref.read(authApiProvider).forgotPassword(email);
      if (mounted) context.push(AppRoutes.resetPasswordFor(email));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      key: const Key('screen.forgotPassword'),
      showBack: true,
      children: [
        ScreenHeading(title: l.forgotTitle, body: l.forgotBody),
        const SizedBox(height: AppSpacing.s6),
        Form(
          key: formKey,
          child: EmailField(controller: _email),
        ),
        const SizedBox(height: AppSpacing.s6),
        if (error != null) ...[
          ErrorBanner(error!),
          const SizedBox(height: AppSpacing.s3),
        ],
        SubmitButton(
          key: const Key('auth.submit'),
          label: l.sendCodeButton,
          loading: busy,
          onPressed: _sendCode,
        ),
        const SizedBox(height: AppSpacing.s2),
        TextButton(
          onPressed: () => context.go(AppRoutes.auth),
          child: Text(l.backToSignIn),
        ),
      ],
    );
  }
}
