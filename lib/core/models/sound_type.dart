enum SoundType {
  click,
  woodblock,
  beep;

  String get displayName {
    switch (this) {
      case SoundType.click: return 'Click';
      case SoundType.woodblock: return 'Woodblock';
      case SoundType.beep: return 'Beep';
    }
  }

  String get assetPath {
    switch (this) {
      case SoundType.click: return 'assets/sounds/click.wav';
      case SoundType.woodblock: return 'assets/sounds/woodblock.wav';
      case SoundType.beep: return 'assets/sounds/beep.wav';
    }
  }

  String get accentAssetPath {
    switch (this) {
      case SoundType.click: return 'assets/sounds/click_accent.wav';
      case SoundType.woodblock: return 'assets/sounds/woodblock_accent.wav';
      case SoundType.beep: return 'assets/sounds/beep_accent.wav';
    }
  }
}
