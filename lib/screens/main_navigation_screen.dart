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
  int _currentIndex = 1; // Start with Upload Screen (index 1)
  final _recordingService = RecordingService();
  bool _isRecording = false;
  
  // Callback to refresh document list
  VoidCallback? _refreshDocumentList;

  // Pages for each tab
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    // Initialize pages with callback
    _pages = [
      DocumentListScreen(
        onVisibilityChanged: () {
          // This will be called when the screen needs to refresh
        },
      ),
      const UploadScreen(),
      const SettingsScreen(),
    ];
    
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
    final previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });
    
    // Trigger refresh when switching to document list from another tab
    if (index == 0 && previousIndex != 0) {
      // Small delay to ensure the widget is built
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          // Force a rebuild which will trigger the document list to refresh
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button from exiting the app when on main navigation
      onWillPop: () async => false,
      child: Scaffold(
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
      ),
    );
  }
}
