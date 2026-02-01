enum VisualMode {
  led,
  flash,
  pendulum;

  String get displayName {
    switch (this) {
      case VisualMode.led: return 'LED';
      case VisualMode.flash: return '閃爍';
      case VisualMode.pendulum: return '擺動';
    }
  }
}
