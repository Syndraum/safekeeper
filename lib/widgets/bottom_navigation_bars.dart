import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'emergency_button_widget.dart';

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
        color: AppTheme.surface,
        boxShadow: AppTheme.shadowSmall,
        border: Border(
          top: BorderSide(
            color: AppTheme.neutral200,
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
                    EmergencyButtonWidget(
                      icon: Icons.warning_rounded,
                      label: 'PANIC',
                      onPressed: onPanicPressed,
                      isPulsingRed: true,
                    ),

                    // Emergency Recording Button - Takes 50% of space
                    EmergencyButtonWidget(
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
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              top: BorderSide(
                color: AppTheme.neutral200,
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
    final color = isSelected ? AppTheme.primary : AppTheme.neutral500;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTabChanged(index),
          borderRadius: AppTheme.borderRadiusSmall,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
