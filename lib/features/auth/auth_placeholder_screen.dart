import 'package:flutter/material.dart';

import '../common/brand_placeholder.dart';

/// Placeholder until the sign-in screens (screen 1) are specified.
class AuthPlaceholderScreen extends StatelessWidget {
  const AuthPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const BrandPlaceholder(key: Key('screen.auth'));
}
