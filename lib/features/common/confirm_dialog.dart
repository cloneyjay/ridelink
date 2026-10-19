import 'package:flutter/material.dart';

/// Two-button confirmation; resolves true only when [confirmLabel] is tapped.
/// Keys: `<keyPrefix>`, `<keyPrefix>.yes`, `<keyPrefix>.no`.
Future<bool> confirmDialog(
  BuildContext context, {
  required String keyPrefix,
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: Key(keyPrefix),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          key: Key('$keyPrefix.no'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          key: Key('$keyPrefix.yes'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message, {Key? key}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(key: key, content: Text(message)));
}
