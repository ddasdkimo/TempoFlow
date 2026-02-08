import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Initialize services
  final metronomeService = container.read(metronomeServiceProvider);
  await metronomeService.initialize();

  final presetService = container.read(presetServiceProvider);
  await presetService.load();

  final usageService = container.read(usageTrackingServiceProvider);
  await usageService.initialize();

  final practiceService = container.read(practiceTrackingServiceProvider);
  await practiceService.initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TempoFlowApp(),
    ),
  );
}
