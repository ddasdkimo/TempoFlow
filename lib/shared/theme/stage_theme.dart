import 'package:flutter/material.dart';

class StageTheme {
  static const backgroundColor = Color(0xFF000000);
  static const accentColor = Color(0xFFFF6B35);
  static const beatActiveColor = Color(0xFFFF6B35);
  static const beatInactiveColor = Color(0xFF333333);
  static const textColor = Color(0xFFFFFFFF);

  static const bpmTextStyle = TextStyle(
    fontSize: 120,
    fontWeight: FontWeight.w200,
    color: textColor,
    letterSpacing: -4,
  );

  static const labelTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: Color(0xFF888888),
  );

  static const buttonTextStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
}
