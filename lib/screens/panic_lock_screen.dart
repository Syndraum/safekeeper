import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Full-screen panic lock overlay that blocks all app interaction
/// Requires password to unlock
class PanicLockScreen extends StatefulWidget {
  final Function(String password) onUnlock;
  final VoidCallback? onUnlockSuccess;

  const PanicLockScreen({
    super.key,
    required this.onUnlock,
    this.onUnlockSuccess,
  });

  @override
  State<PanicLockScreen> createState() => _PanicLockScreenState();
}

class _PanicLockScreenState extends State<PanicLockScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isUnlocking = false;
  int _failedAttempts = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup shake animation for failed attempts
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _attemptUnlock() async {
    if (_passwordController.text.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() {
      _isUnlocking = true;
    });

    try {
      // Call the unlock callback with the password
      await widget.onUnlock(_passwordController.text);
      
      // If we reach here, unlock was successful
      if (mounted) {
        widget.onUnlockSuccess?.call();
      }
    } catch (e) {
      // Unlock failed
      if (mounted) {
        setState(() {
          _failedAttempts++;
          _isUnlocking = false;
        });
        
        _passwordController.clear();
        _shakeController.forward(from: 0);
        
        _showError('Incorrect password ($_failedAttempts attempt${_failedAttempts > 1 ? 's' : ''})');
        
        // Add delay after multiple failed attempts
        if (_failedAttempts >= 3) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button from dismissing the lock screen
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Panic lock icon with pulsing animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacing32),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.error,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.error.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 80,
                              color: AppTheme.error,
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        // Restart animation for pulsing effect
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing48),

                    // Title
                    Text(
                      'APP LOCKED',
                      style: AppTheme.heading1.copyWith(
                        color: AppTheme.error,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),

                    // Subtitle
                    Text(
                      'Panic mode activated\nEnter password to unlock',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing48),

                    // Password input card
                    Card(
                      elevation: 0,
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.borderRadiusLarge,
                        side: BorderSide(
                          color: AppTheme.error.withValues(alpha: 0.3),
                          width: 1,
                        ),
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
                              enabled: !_isUnlocking,
                              onSubmitted: (_) => _attemptUnlock(),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Colors.white70),
                                hintText: 'Enter your password',
                                hintStyle: const TextStyle(color: Colors.white38),
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppTheme.error,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: AppTheme.borderRadiusMedium,
                                  borderSide: BorderSide(color: AppTheme.error),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppTheme.borderRadiusMedium,
                                  borderSide: BorderSide(
                                    color: AppTheme.error.withValues(alpha: 0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppTheme.borderRadiusMedium,
                                  borderSide: BorderSide(
                                    color: AppTheme.error,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.black.withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing24),

                            // Unlock button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isUnlocking ? null : _attemptUnlock,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.error,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppTheme.spacing16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppTheme.borderRadiusMedium,
                                  ),
                                  elevation: 0,
                                ),
                                child: _isUnlocking
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
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.lock_open_rounded),
                                          SizedBox(width: AppTheme.spacing8),
                                          Text(
                                            'UNLOCK',
                                            style: AppTheme.button.copyWith(
                                              letterSpacing: 1.2,
                                            ),
                                          ),
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
                                    Icon(
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
                                          fontWeight: FontWeight.bold,
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
                    const SizedBox(height: AppTheme.spacing32),

                    // Security notice
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: AppTheme.borderRadiusMedium,
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Expanded(
                            child: Text(
                              'All app functions are blocked until unlocked',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.white70,
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
    );
  }
}
