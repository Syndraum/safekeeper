import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bars.dart';
import '../services/recording_service.dart';
import 'document_list_screen.dart';
import 'upload_screen.dart';
import 'settings_screen.dart';

/// Main navigation screen with dual bottom navigation
/// Hosts the three main screens: Document List, Upload, and Settings
class MainNavigationScreen extends StatefulWidget {
  final VoidCallback? onPanicPressed;
  final VoidCallback? onEmergencyRecordingPressed;

  const MainNavigationScreen({
    super.key,
    this.onPanicPressed,
    this.onEmergencyRecordingPressed,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final _recordingService = RecordingService();
  bool _isRecording = false;

  // Pages for each tab
  final List<Widget> _pages = const [
    DocumentListScreen(),
    UploadScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Listen to recording state
    _recordingService.recordingStateStream.listen((isRecording) {
      if (mounted) {
        setState(() {
          _isRecording = isRecording;
        });
      }
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: DualBottomNavigationBars(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
        onPanicPressed: widget.onPanicPressed ?? () {},
        onEmergencyRecordingPressed: widget.onEmergencyRecordingPressed ?? () {},
        isRecording: _isRecording,
      ),
    );
  }
}
