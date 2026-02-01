import 'package:flutter/material.dart';

import 'features/metronome/metronome_screen.dart';
import 'shared/theme/app_theme.dart';

class TempoFlowApp extends StatelessWidget {
  const TempoFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TempoFlow',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const MetronomeScreen(),
    );
  }
}
