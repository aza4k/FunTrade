import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumDialog extends StatelessWidget {
  final String title;
  final String message;
  final Widget? content;
  final String confirmText;
  final String? cancelText;
  final String emoji;
  final IconData? buttonIcon;
  final bool isError;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const PremiumDialog({
    super.key,
    required this.title,
    required this.message,
    this.content,
    required this.confirmText,
    this.cancelText,
    required this.emoji,
    this.buttonIcon,
    this.onConfirm,
    this.onCancel,
    this.isError = false,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    Widget? content,
    String confirmText = 'Great',
    String? cancelText,
    String emoji = '🎉',
    IconData? buttonIcon,
    bool isError = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x99000000), // Soft dark backdrop
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.transparent,
          child: Center(
            child: PremiumDialog(
              title: title,
              message: message,
              content: content,
              confirmText: confirmText,
              cancelText: cancelText,
              emoji: emoji,
              buttonIcon: buttonIcon,
              isError: isError,
              onConfirm: () {
                Navigator.pop(context);
                if (onConfirm != null) onConfirm();
              },
              onCancel: () {
                Navigator.pop(context);
                if (onCancel != null) onCancel();
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * 100, 0.0)
            ..scaleByDouble(anim1.value, anim1.value, 1.0, 1.0),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoColors.white, // Pure white layout card as requested
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 32,
            offset: Offset(0, 12),
            spreadRadius: -4,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji bubble
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isError ? const Color(0xFFF43F5E) : const Color(0xFF0ECB81)).withValues(alpha: 0.1),
              border: Border.all(
                color: (isError ? const Color(0xFFF43F5E) : const Color(0xFF0ECB81)).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 34),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF1F1F1F),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Description Message or Content
          content ??
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6B7280), // Neutral slate-gray text
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
          const SizedBox(height: 24),

          // Action buttons
          Column(
            children: [
              // Main Action Button (Green/Gradient)
              GestureDetector(
                onTap: onConfirm,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: isError
                        ? const LinearGradient(
                            colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF5AD234), Color(0xFF3AA81C)], // Vibrant Apple Green from the screenshot
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isError ? const Color(0xFFF43F5E) : const Color(0xFF3AA81C)).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (buttonIcon != null) ...[
                        Icon(buttonIcon, color: CupertinoColors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        confirmText,
                        style: GoogleFonts.plusJakartaSans(
                          color: CupertinoColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Cancel Button (if provided)
              if (cancelText != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6), // Light gray background
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cancelText!,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1F1F1F),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
