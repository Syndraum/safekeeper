import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/upload_screen.dart';
import 'screens/document_list_screen.dart';
import 'screens/password_setup_screen.dart';
import 'screens/unlock_screen.dart';
import 'screens/settings_screen.dart';
import 'services/encryption_service.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'services/cloud_backup_service.dart';
import 'services/document_service.dart';
import 'services/cloud_providers/google_drive_provider.dart';
import 'services/cloud_providers/dropbox_provider.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/document_list_view_model.dart';
import 'viewmodels/upload_view_model.dart';
import 'viewmodels/settings_view_model.dart';
import 'viewmodels/home_view_model.dart';
import 'widgets/emergency_recording_wrapper.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final encryptionService = EncryptionService();
  await encryptionService.initialize();

  final settingsService = SettingsService();
  await settingsService.initialize();

  final backupService = CloudBackupService();
  await backupService.initialize();

  final authService = AuthService();
  final documentService = DocumentService();
  final googleDriveProvider = GoogleDriveProvider();
  final dropboxProvider = DropboxProvider();

  // Check if password is set
  final isPasswordSet = await authService.isPasswordSet();

  runApp(
    MyApp(
      isPasswordSet: isPasswordSet,
      authService: authService,
      encryptionService: encryptionService,
      documentService: documentService,
      settingsService: settingsService,
      backupService: backupService,
      googleDriveProvider: googleDriveProvider,
      dropboxProvider: dropboxProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isPasswordSet;
  final AuthService authService;
  final EncryptionService encryptionService;
  final DocumentService documentService;
  final SettingsService settingsService;
  final CloudBackupService backupService;
  final GoogleDriveProvider googleDriveProvider;
  final DropboxProvider dropboxProvider;

  const MyApp({
    super.key,
    required this.isPasswordSet,
    required this.authService,
    required this.encryptionService,
    required this.documentService,
    required this.settingsService,
    required this.backupService,
    required this.googleDriveProvider,
    required this.dropboxProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>.value(value: authService),
        Provider<EncryptionService>.value(value: encryptionService),
        Provider<DocumentService>.value(value: documentService),
        Provider<SettingsService>.value(value: settingsService),
        Provider<CloudBackupService>.value(value: backupService),
        Provider<GoogleDriveProvider>.value(value: googleDriveProvider),
        Provider<DropboxProvider>.value(value: dropboxProvider),

        // ViewModels
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => DocumentListViewModel(
            documentService: documentService,
            encryptionService: encryptionService,
            backupService: backupService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UploadViewModel(
            encryptionService: encryptionService,
            documentService: documentService,
            backupService: backupService,
            settingsService: settingsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(
            settingsService: settingsService,
            backupService: backupService,
            googleDriveProvider: googleDriveProvider,
            dropboxProvider: dropboxProvider,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(authService: authService),
        ),
      ],
      child: MaterialApp(
      title: 'SafeKeeper - Gestion de Documents Sécurisés',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 36, 77, 124),
        ),
        useMaterial3: true,
      ),
        // Wrap the entire app with emergency recording functionality
        builder: (context, child) {
          return EmergencyRecordingWrapper(
            child: child ?? const SizedBox.shrink(),
          );
        },
        // Définit les routes pour naviguer entre écrans
        routes: {
          '/': (context) =>
              const MyHomePage(title: 'SafeKeeper - Documents Sécurisés'),
          '/upload': (context) => const UploadScreen(),
          '/list': (context) => const DocumentListScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/password-setup': (context) => const PasswordSetupScreen(),
          '/unlock': (context) => const UnlockScreen(),
        },
        // Route initiale basée sur l'état du mot de passe
        initialRoute: isPasswordSet ? '/unlock' : '/password-setup',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _logout() {
    final viewModel = context.read<HomeViewModel>();
    viewModel.logout();
    Navigator.of(context).pushReplacementNamed('/unlock');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            tooltip: 'Verrouiller',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône de sécurité
              Icon(
                Icons.shield_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),

              // Titre de bienvenue
              Text(
                'Bienvenue dans SafeKeeper',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'Vos documents sont protégés par un chiffrement de niveau militaire',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Bouton pour uploader un document
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/upload'),
                icon: const Icon(Icons.upload_file, size: 28),
                label: const Text(
                  'Uploader un document',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton pour voir la liste des documents
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/list'),
                icon: const Icon(Icons.folder_open, size: 28),
                label: const Text(
                  'Voir mes documents',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
              const SizedBox(height: 40),

              // Informations de sécurité
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sécurité active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RSA-2048 + AES-256 + HMAC-SHA256',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
