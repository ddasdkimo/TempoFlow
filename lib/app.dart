import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/providers.dart';
import 'features/metronome/metronome_screen.dart';
import 'shared/theme/app_theme.dart';

class TempoFlowApp extends ConsumerStatefulWidget {
  const TempoFlowApp({super.key});

  @override
  ConsumerState<TempoFlowApp> createState() => _TempoFlowAppState();
}

class _TempoFlowAppState extends ConsumerState<TempoFlowApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final usageService = ref.read(usageTrackingServiceProvider);
    final practiceService = ref.read(practiceTrackingServiceProvider);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        usageService.onAppPaused();
        practiceService.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        usageService.onAppResumed();
        practiceService.onAppResumed();
        break;
      default:
        break;
    }
  }

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
