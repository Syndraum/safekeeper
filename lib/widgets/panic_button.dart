import 'package:flutter/material.dart';

/// Panic button widget that triggers app lock when pressed
class PanicButton extends StatefulWidget {
  final VoidCallback onPanic;

  const PanicButton({
    super.key,
    required this.onPanic,
  });

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Setup subtle pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePanic() {
    setState(() {
      _isPressed = true;
    });

    // Haptic feedback would be nice here
    widget.onPanic();

    // Reset pressed state after animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive button size
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = (screenWidth * 0.18).clamp(56.0, 80.0);
    final iconSize = (buttonSize * 0.5).clamp(28.0, 40.0);

    return Positioned(
      left: 24,
      bottom: 24 + MediaQuery.of(context).padding.bottom,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.9 : _pulseAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Button
                Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: _handlePanic,
                    backgroundColor: Colors.red[700],
                    elevation: 8,
                    heroTag: 'panic_button',
                    child: Icon(
                      Icons.warning_rounded,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Label
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
