import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../core/constants/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderCol;
  final Color? bgCol;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderCol,
    this.bgCol,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final finalRadius = borderRadius ?? BorderRadius.circular(20);
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: finalRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: finalRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (bgCol ?? AppColors.surface).withValues(alpha: 0.92),
                  (bgCol ?? AppColors.surface).withValues(alpha: 0.80),
                ],
              ),
              borderRadius: finalRadius,
              border: Border.all(
                color: borderCol ?? AppColors.border.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Stack(
              children: [
                // Subtle top edge highlight for depth
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: finalRadius.topLeft,
                        topRight: finalRadius.topRight,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          CupertinoColors.white.withValues(alpha: 0.0),
                          CupertinoColors.white.withValues(alpha: 0.06),
                          CupertinoColors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
