import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/password_setup_screen.dart';
import 'screens/unlock_screen.dart';
import 'screens/permissions_onboarding_screen.dart';
import 'services/encryption_service.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'services/cloud_backup_service.dart';
import 'services/document_service.dart';
import 'services/cache_service.dart';
import 'services/permission_service.dart';
import 'services/cloud_providers/google_drive_provider.dart';
import 'services/cloud_providers/dropbox_provider.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/document_list_view_model.dart';
import 'viewmodels/upload_view_model.dart';
import 'viewmodels/settings_view_model.dart';
import 'viewmodels/home_view_model.dart';
import 'widgets/emergency_recording_wrapper.dart';

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

  final cacheService = CacheService();
  await cacheService.initialize();

  final permissionService = PermissionService();
  await permissionService.initialize();

  final authService = AuthService();
  final documentService = DocumentService();
  final googleDriveProvider = GoogleDriveProvider();
  final dropboxProvider = DropboxProvider();

  // Check if password is set
  final isPasswordSet = await authService.isPasswordSet();
  
  // Check if permissions onboarding is completed
  final isPermissionsOnboardingCompleted = 
      permissionService.isPermissionsOnboardingCompleted();

  runApp(
    MyApp(
      isPasswordSet: isPasswordSet,
      isPermissionsOnboardingCompleted: isPermissionsOnboardingCompleted,
      authService: authService,
      encryptionService: encryptionService,
      documentService: documentService,
      settingsService: settingsService,
      backupService: backupService,
      cacheService: cacheService,
      permissionService: permissionService,
      googleDriveProvider: googleDriveProvider,
      dropboxProvider: dropboxProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isPasswordSet;
  final bool isPermissionsOnboardingCompleted;
  final AuthService authService;
  final EncryptionService encryptionService;
  final DocumentService documentService;
  final SettingsService settingsService;
  final CloudBackupService backupService;
  final CacheService cacheService;
  final PermissionService permissionService;
  final GoogleDriveProvider googleDriveProvider;
  final DropboxProvider dropboxProvider;

  const MyApp({
    super.key,
    required this.isPasswordSet,
    required this.isPermissionsOnboardingCompleted,
    required this.authService,
    required this.encryptionService,
    required this.documentService,
    required this.settingsService,
    required this.backupService,
    required this.cacheService,
    required this.permissionService,
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
        Provider<CacheService>.value(value: cacheService),
        Provider<PermissionService>.value(value: permissionService),
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
            cacheService: cacheService,
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
            cacheService: cacheService,
            googleDriveProvider: googleDriveProvider,
            dropboxProvider: dropboxProvider,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(authService: authService),
        ),
      ],
      child: _AppWithEmergencyWrapper(
        isPasswordSet: isPasswordSet,
        isPermissionsOnboardingCompleted: isPermissionsOnboardingCompleted,
      ),
    );
  }
}

/// Wrapper widget that integrates emergency functionality with navigation
class _AppWithEmergencyWrapper extends StatefulWidget {
  final bool isPasswordSet;
  final bool isPermissionsOnboardingCompleted;

  const _AppWithEmergencyWrapper({
    required this.isPasswordSet,
    required this.isPermissionsOnboardingCompleted,
  });

  @override
  State<_AppWithEmergencyWrapper> createState() =>
      _AppWithEmergencyWrapperState();
}

class _AppWithEmergencyWrapperState extends State<_AppWithEmergencyWrapper> {
  VoidCallback? _panicCallback;
  VoidCallback? _recordingCallback;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  void _setPanicCallback(VoidCallback callback) {
    if (mounted) {
      setState(() {
        _panicCallback = callback;
      });
    }
  }

  void _setRecordingCallback(VoidCallback callback) {
    if (mounted) {
      setState(() {
        _recordingCallback = callback;
      });
    }
  }

  String _getInitialRoute() {
    // First launch: password setup → permissions onboarding → main app
    // Subsequent launches: unlock → main app
    if (!widget.isPasswordSet) {
      return '/password-setup';
    } else if (!widget.isPermissionsOnboardingCompleted) {
      return '/permissions-onboarding';
    } else {
      return '/unlock';
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmergencyRecordingWrapper(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      onPanicCallback: _setPanicCallback,
      onRecordingCallback: _setRecordingCallback,
      child: MaterialApp(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        title: 'SafeKeeper - Secure Document Management',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        // Define routes for navigating between screens
        routes: {
          '/': (context) => MainNavigationScreen(
                onPanicPressed: _panicCallback ?? () {},
                onEmergencyRecordingPressed: _recordingCallback ?? () {},
              ),
          '/password-setup': (context) => const PasswordSetupScreen(),
          '/permissions-onboarding': (context) => const PermissionsOnboardingScreen(),
          '/unlock': (context) => const UnlockScreen(),
        },
        // Initial route based on password and permissions status
        initialRoute: _getInitialRoute(),
      ),
    );
  }
}
