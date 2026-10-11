import 'package:flutter/material.dart';

import '../common/brand_placeholder.dart';

/// Placeholder until the home screen (screen 2) is specified.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const BrandPlaceholder(key: Key('screen.home'));
}
