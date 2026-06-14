import 'package:flutter/cupertino.dart';
import '../core/constants/colors.dart';

class LiquidBackground extends StatelessWidget {
  final Widget child;

  const LiquidBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base canvas color
        Container(
          color: AppColors.background,
        ),

        // Primary Blue liquid blob at top-left (larger, more dramatic)
        Positioned(
          top: -140,
          left: -120,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0E76FD).withValues(alpha: 0.30),
                  const Color(0xFF0E76FD).withValues(alpha: 0.08),
                  const Color(0xFF0E76FD).withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Purple/Violet liquid blob at bottom-right
        Positioned(
          bottom: 40,
          right: -140,
          child: Container(
            width: 480,
            height: 480,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.22),
                  const Color(0xFF7C3AED).withValues(alpha: 0.06),
                  const Color(0xFF7C3AED).withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Emerald Green liquid blob in the middle-left
        Positioned(
          top: 320,
          left: -120,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0ECB81).withValues(alpha: 0.18),
                  const Color(0xFF0ECB81).withValues(alpha: 0.04),
                  const Color(0xFF0ECB81).withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Warm Amber/Gold liquid blob at top-right for premium warmth
        Positioned(
          top: 80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  const Color(0xFFF59E0B).withValues(alpha: 0.03),
                  const Color(0xFFF59E0B).withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Very subtle noise/grain texture overlay
        Positioned.fill(
          child: Container(
            color: const Color(0xFF0A0C10).withValues(alpha: 0.02),
          ),
        ),

        // Renders the child components on top
        child,
      ],
    );
  }
}
