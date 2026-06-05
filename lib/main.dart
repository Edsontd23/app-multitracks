import 'package:app_multitracks/shared/navigation/navigation_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AppMultitracks(),
    ),
  );
}

class AppMultitracks extends StatelessWidget {
  const AppMultitracks({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'APP MULTITRACKS',
      theme: AppTheme.dark(),
      home: const NavigationShell(),
    );
  }
}