import 'package:flutter/widgets.dart';

import '../../core/api/api_exception.dart';
import '../../l10n/app_localizations.dart';
import 'auth_errors.dart';

/// Busy/error handling shared by the auth forms.
mixin AuthFormState<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  bool busy = false;
  String? error;

  /// Validates, runs [action], and turns API failures into [error].
  Future<void> submit(
    Future<void> Function() action, {
    AuthUnauthorized on401 = AuthUnauthorized.wrongCredentials,
    bool validate = true,
    Future<bool> Function(ApiException e)? onApiError,
  }) async {
    if (busy) return;
    if (validate && !(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      busy = true;
      error = null;
    });
    final l = AppLocalizations.of(context);
    try {
      await action();
    } on ApiException catch (e) {
      final handled = await onApiError?.call(e) ?? false;
      if (!handled && mounted) {
        setState(() => error = authErrorMessage(e, l, on401: on401));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
