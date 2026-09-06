import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/home/home_shell.dart';
import 'presentation/screens/profile/profile_selection_screen.dart';

void main() {
  runApp(const ProviderScope(child: OtakuTrackerApp()));
}

class OtakuTrackerApp extends ConsumerWidget {
  const OtakuTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return MaterialApp(
      title: 'Otaku Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: activeProfile == null
          ? const ProfileSelectionScreen()
          : const HomeShell(),
    );
  }
}
