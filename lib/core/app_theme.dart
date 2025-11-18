import 'package:flutter/material.dart';

/// Centralized design system for SafeKeeper app
/// Following 8px grid system (4px for fine details)
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // ============================================================================
  // COLORS
  // ============================================================================
  
  /// Primary brand color - Vibrant Indigo
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  /// Secondary color - Purple
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryLight = Color(0xFFA78BFA);
  
  /// Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  
  /// Neutral colors (grey scale)
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);
  
  /// Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = neutral50;
  
  /// Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = neutral100;
  
  // ============================================================================
  // SPACING (8px grid system, 4px for details)
  // ============================================================================
  
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;
  
  // ============================================================================
  // BORDER RADIUS (following 8px grid)
  // ============================================================================
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXLarge => BorderRadius.circular(radiusXLarge);
  
  // ============================================================================
  // ELEVATION & SHADOWS
  // ============================================================================
  
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: neutral900.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: neutral900.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: neutral900.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================
  
  static const String fontFamily = 'SF Pro Display'; // Falls back to system font
  
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
  );
  
  static const TextStyle heading5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle heading6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: neutral500,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.2,
  );
  
  // ============================================================================
  // THEME DATA
  // ============================================================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: primary,
        primaryContainer: primaryLight,
        secondary: secondary,
        secondaryContainer: secondaryLight,
        error: error,
        errorContainer: errorLight,
        background: background,
        surface: surface,
        surfaceVariant: surfaceVariant,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onBackground: neutral900,
        onSurface: neutral900,
        onSurfaceVariant: neutral600,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: background,
      
      // App Bar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surface,
        foregroundColor: neutral900,
        titleTextStyle: heading4.copyWith(color: neutral900),
        iconTheme: const IconThemeData(color: neutral900),
      ),
      
      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        color: surface,
        shadowColor: neutral900.withOpacity(0.08),
        margin: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
          ),
          textStyle: button,
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
          ),
          textStyle: button.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
          ),
          textStyle: button,
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutral50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide(color: neutral200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide(color: error, width: 2),
        ),
        labelStyle: bodyMedium.copyWith(color: neutral600),
        hintStyle: bodyMedium.copyWith(color: neutral400),
        errorStyle: bodySmall.copyWith(color: error),
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
      ),
      
      // Icon
      iconTheme: const IconThemeData(
        color: neutral700,
        size: 24,
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: neutral200,
        thickness: 1,
        space: spacing16,
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: neutral800,
        contentTextStyle: bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusLarge,
        ),
        titleTextStyle: heading4.copyWith(color: neutral900),
        contentTextStyle: bodyMedium.copyWith(color: neutral700),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: neutral500,
        selectedLabelStyle: bodySmall.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: bodySmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        headlineMedium: heading4,
        headlineSmall: heading5,
        titleLarge: heading6,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: button,
        labelSmall: caption,
      ),
    );
  }
  
  // ============================================================================
  // CUSTOM WIDGETS STYLES
  // ============================================================================
  
  /// Primary button decoration
  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
    color: primary,
    borderRadius: borderRadiusMedium,
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  /// Secondary button decoration
  static BoxDecoration get secondaryButtonDecoration => BoxDecoration(
    color: surface,
    borderRadius: borderRadiusMedium,
    border: Border.all(color: neutral200, width: 1.5),
  );
  
  /// Card decoration with shadow
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: borderRadiusMedium,
    boxShadow: shadowSmall,
  );
  
  /// Search bar decoration
  static BoxDecoration get searchBarDecoration => BoxDecoration(
    color: neutral50,
    borderRadius: borderRadiusMedium,
    border: Border.all(color: neutral200, width: 1),
  );
  
  /// Icon container decoration
  static BoxDecoration iconContainerDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: borderRadiusSmall,
  );
  
  /// Success container decoration
  static BoxDecoration get successContainerDecoration => BoxDecoration(
    color: success.withOpacity(0.1),
    borderRadius: borderRadiusMedium,
    border: Border.all(color: success.withOpacity(0.3), width: 1),
  );
  
  /// Warning container decoration
  static BoxDecoration get warningContainerDecoration => BoxDecoration(
    color: warning.withOpacity(0.1),
    borderRadius: borderRadiusMedium,
    border: Border.all(color: warning.withOpacity(0.3), width: 1),
  );
  
  /// Error container decoration
  static BoxDecoration get errorContainerDecoration => BoxDecoration(
    color: error.withOpacity(0.1),
    borderRadius: borderRadiusMedium,
    border: Border.all(color: error.withOpacity(0.3), width: 1),
  );
}
