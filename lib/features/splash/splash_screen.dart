import 'package:flutter/material.dart';

import '../common/brand_placeholder.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const BrandPlaceholder(key: Key('screen.splash'), showProgress: true);
}
