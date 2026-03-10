import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryRed = Color(0xFFD31027);
  static const Color primaryDarkRed = Color(0xFF8A0000);
  
  // Backgrounds
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardDarkBackground = Color(0xFF1E1E1E);
  
  // Gradients
  static const Gradient buttonGradientRed = LinearGradient(
    colors: [Color(0xFFE52D27), Color(0xFFB31217)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const Gradient buttonGradientGold = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient textGradientGold = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFE066), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Text Colors
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFAAAAAA);
  static const Color textDark = Color(0xFF1A1A1A);
  
  // Input Fields
  static const Color inputBackground = Color(0xFF262626);
  static const Color inputBorder = Color(0xFF333333);
}
