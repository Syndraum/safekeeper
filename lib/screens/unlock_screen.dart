import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../services/recording_service.dart';
import '../services/cache_service.dart';
import '../widgets/emergency_button_widget.dart';
import '../screens/panic_lock_screen.dart';

/// Écran de déverrouillage pour accéder aux documents
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
            content: Text('Enregistrement d\'urgence sauvegardé'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de la sauvegarde de l\'enregistrement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Check permissions first
      final hasPermissions = await _recordingService.checkPermissions();
      if (!hasPermissions && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autorisations caméra et microphone requises'),
            backgroundColor: Colors.orange,
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
            content: Text('Échec du démarrage de l\'enregistrement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unlock() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre mot de passe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final viewModel = context.read<AuthViewModel>();
    final password = _passwordController.text;
    final success = await viewModel.verifyPassword(password);

    if (mounted) {
      if (success) {
        // Mot de passe correct - naviguer vers l'écran principal
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        // Mot de passe incorrect
        setState(() {
          _failedAttempts++;
        });

        _passwordController.clear();

        // Show error from ViewModel or default message
        final errorMessage = viewModel.hasError
            ? viewModel.error!.message
            : 'Mot de passe incorrect (${_failedAttempts} tentative${_failedAttempts > 1 ? 's' : ''})';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );

        // Ajouter un délai après plusieurs tentatives échouées
        if (_failedAttempts >= 3) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    
    return Stack(
      children: [
        // Main unlock screen
        Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icône
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Titre
                  const Text(
                    'SafeKeeper',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sous-titre
                  Text(
                    'Entrez votre mot de passe pour accéder à vos documents',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Carte de saisie
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Champ mot de passe
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            autofocus: true,
                            onSubmitted: (_) => _unlock(),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              hintText: 'Entrez votre mot de passe',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bouton de déverrouillage
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: viewModel.isBusy ? null : _unlock,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
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
                                        Icon(Icons.lock_open),
                                        SizedBox(width: 8),
                                        Text(
                                          'Déverrouiller',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // Indicateur de tentatives échouées
                          if (_failedAttempts > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.red[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _failedAttempts == 1
                                          ? 'Mot de passe incorrect'
                                          : '$_failedAttempts tentatives échouées',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 12,
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
                  const SizedBox(height: 24),

                  // Emergency buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Panic Button
                        EmergencyButtonWidget(
                          icon: Icons.warning_rounded,
                          label: 'PANIC',
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
                  const SizedBox(height: 24),

                  // Note de sécurité
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Vos documents sont protégés par un chiffrement de niveau militaire',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
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
    );
  }
}
