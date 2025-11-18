import 'package:flutter/material.dart';

/// Custom dual bottom navigation widget
/// First bar: Emergency action buttons (top)
/// Second bar: Main navigation tabs (bottom)
class DualBottomNavigationBars extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final VoidCallback onPanicPressed;
  final VoidCallback onEmergencyRecordingPressed;
  final bool isRecording;

  const DualBottomNavigationBars({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.onPanicPressed,
    required this.onEmergencyRecordingPressed,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // First Bar - Emergency Actions (now on top)
        Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    // Panic Button - Takes 50% of space
                    _buildEmergencyButton(
                      context,
                      icon: Icons.warning_rounded,
                      label: 'PANIC',
                      onPressed: onPanicPressed,
                      isPulsingRed: true,
                    ),

                    // Emergency Recording Button - Takes 50% of space
                    _buildEmergencyButton(
                      context,
                      icon: isRecording ? Icons.stop : Icons.videocam,
                      label: isRecording ? 'STOP' : 'RECORD',
                      onPressed: onEmergencyRecordingPressed,
                      isPulsingRed: isRecording,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Second Bar - Main Navigation (now on bottom)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 26),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            )
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.folder_open,
                    label: 'Files',
                    index: 0,
                    isSelected: currentIndex == 0,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.add_circle_outline,
                    label: 'Add',
                    index: 1,
                    isSelected: currentIndex == 1,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.settings,
                    label: 'Settings',
                    index: 2,
                    isSelected: currentIndex == 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () => onTabChanged(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPulsingRed = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.red.withOpacity(0.15),
            highlightColor: Colors.red.withOpacity(0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isPulsingRed 
                    ? Colors.red.shade50
                    : Colors.red.shade50.withOpacity(0.5),
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
                        ? Colors.red.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
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
