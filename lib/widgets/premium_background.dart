import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;
  final bool showImage;

  const PremiumBackground({
    super.key,
    required this.child,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            const Color(0xFF1E1E1E), // Slightly lighter at center
            AppColors.darkBackground,
            const Color(0xFF0F0F0F), // Deepest charcoal at edges
          ],
        ),
      ),
      child: Stack(
        children: [
          if (showImage)
            Opacity(
              opacity: 0.15, // Subtle image overlay
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/home_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          // Gradient Overlay for "Redcodel" look
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  AppColors.primaryRed.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
