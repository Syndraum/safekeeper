import 'package:flutter/material.dart';

/// Reusable emergency button widget with consistent design
/// Used in both navigation bars and unlock screen
class EmergencyButtonWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPulsingRed;

  const EmergencyButtonWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPulsingRed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.red.withValues(alpha: 0.15),
            highlightColor: Colors.red.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isPulsingRed 
                    ? Colors.red.shade50
                    : Colors.red.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPulsingRed 
                      ? Colors.red.shade400
                      : Colors.red.shade300,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPulsingRed 
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: isPulsingRed ? 6 : 3,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isPulsingRed 
                        ? Colors.red.shade700 
                        : Colors.red.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isPulsingRed 
                          ? Colors.red.shade700 
                          : Colors.red.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
