import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../viewmodels/auth_view_model.dart';
import '../services/recording_service.dart';
import '../services/cache_service.dart';
import '../widgets/emergency_button_widget.dart';
import '../screens/panic_lock_screen.dart';

/// Unlock screen to access documents
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordController = TextEditingController();
  final _recordingService = RecordingService();
  final _cacheService = CacheService();

  bool _isPasswordVisible = false;
  int _failedAttempts = 0;
  bool _isRecording = false;
  bool _isPanicLocked = false;
  StreamSubscription<bool>? _recordingStateSubscription;

  @override
  void initState() {
    super.initState();
    
    // Listen to recording state changes
    _recordingStateSubscription = _recordingService.recordingStateStream.listen((isRecording) {
      if (mounted) {
        setState(() {
          _isRecording = isRecording;
        });
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _recordingStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handlePanic() async {
    // Clear cache for security
    await _cacheService.clearAllCache();
    
    // Show panic lock screen overlay
    setState(() {
      _isPanicLocked = true;
    });
  }

  Future<void> _handleUnlockFromPanic(String password) async {
    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.verifyPassword(password);
    
    if (success) {
      // Password correct - dismiss panic lock
      if (mounted) {
        setState(() {
          _isPanicLocked = false;
        });
      }
    } else {
      // Password incorrect - throw error to be caught by PanicLockScreen
      throw Exception('Incorrect password');
    }
  }

  Future<void> _handleEmergencyRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _recordingService.stopRecording();
      if (path != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Emergency recording saved'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save recording'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } else {
      // Check permissions first
      final hasPermissions = await _recordingService.checkPermissions();
      if (!hasPermissions && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and microphone permissions required'),
            backgroundColor: AppTheme.warning,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Start recording
      final success = await _recordingService.startRecording();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start recording'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _unlock() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final viewModel = context.read<AuthViewModel>();
    final password = _passwordController.text;
    final success = await viewModel.verifyPassword(password);

    if (mounted) {
      if (success) {
        // Correct password - navigate to main screen and clear navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        // Incorrect password
        setState(() {
          _failedAttempts++;
        });

        _passwordController.clear();

        // Show error from ViewModel or default message
        final errorMessage = viewModel.hasError
            ? viewModel.error!.message
            : 'Incorrect password (${_failedAttempts} attempt${_failedAttempts > 1 ? 's' : ''})';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.error,
          ),
        );

        // Add delay after multiple failed attempts
        if (_failedAttempts >= 3) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    
    return WillPopScope(
      // Prevent back button from bypassing the unlock screen
      onWillPop: () async => false,
      child: Stack(
        children: [
          // Main unlock screen
          Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.shadowLarge,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing32),

                  // Title
                  Text(
                    'SafeKeeper',
                    style: AppTheme.heading1.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),

                  // Subtitle
                  Text(
                    'Enter your password to access your documents',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.95),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing48),

                  // Input card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusLarge,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      child: Column(
                        children: [
                          // Password field
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            autofocus: true,
                            onSubmitted: (_) => _unlock(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing24),

                          // Unlock button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: viewModel.isBusy ? null : _unlock,
                              child: viewModel.isBusy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock_open_rounded),
                                        SizedBox(width: AppTheme.spacing8),
                                        Text('Unlock'),
                                      ],
                                    ),
                            ),
                          ),

                          // Failed attempts indicator
                          if (_failedAttempts > 0) ...[
                            const SizedBox(height: AppTheme.spacing16),
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacing12),
                              decoration: AppTheme.errorContainerDecoration,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppTheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spacing8),
                                  Expanded(
                                    child: Text(
                                      _failedAttempts == 1
                                          ? 'Incorrect password'
                                          : '$_failedAttempts failed attempts',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),

                  // Emergency buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
                    child: Row(
                      children: [
                        // Panic Button
                        EmergencyButtonWidget(
                          icon: Icons.warning_rounded,
                          label: 'SOS',
                          onPressed: _handlePanic,
                          isPulsingRed: true,
                        ),

                        // Emergency Recording Button
                        EmergencyButtonWidget(
                          icon: _isRecording ? Icons.stop : Icons.videocam,
                          label: _isRecording ? 'STOP' : 'RECORD',
                          onPressed: _handleEmergencyRecording,
                          isPulsingRed: _isRecording,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),

                  // Security note
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: AppTheme.borderRadiusMedium,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.white.withOpacity(0.95),
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Expanded(
                          child: Text(
                            'Your documents are protected by military-grade encryption',
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
          ),
          
          // Panic lock screen overlay (blocks everything when active)
          if (_isPanicLocked)
            Positioned.fill(
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color.fromARGB(255, 36, 77, 124),
                  ),
                  useMaterial3: true,
                ),
                home: PanicLockScreen(
                  onUnlock: _handleUnlockFromPanic,
                  onUnlockSuccess: () {
                    if (mounted) {
                      setState(() {
                        _isPanicLocked = false;
                      });
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
