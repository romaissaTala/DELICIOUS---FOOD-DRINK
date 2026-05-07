import 'package:flutter/material.dart';

class AppTheme {
  // ============================================
  // BRAND COLORS
  // ============================================

  // Primary Brand Colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenLight = Color(0xFF4CAF50);
  static const Color primaryGreenDark = Color(0xFF1B5E20);

  // Secondary Brand Colors
  static const Color secondaryOrange = Color(0xFFFF9800);
  static const Color secondaryOrangeLight = Color(0xFFFFB74D);
  static const Color secondaryOrangeDark = Color(0xFFF57C00);

  // Accent Colors
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color accentYellow = Color(0xFFFFC107);

  // Neutral Colors
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF212121);
  static const Color neutralGrey = Color(0xFF757575);
  static const Color neutralLightGrey = Color(0xFFF5F5F5);
  static const Color neutralDarkGrey = Color(0xFF424242);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // ============================================
  // PRODUCT GRADIENT COLORS
  // ============================================

  /// Product-specific gradient colors for dynamic UI
  static const Map<String, List<Color>> productGradients = {
    'coca-cola': [Color(0xFFCC0000), Color(0xFFFF4444), Color(0xFFFF8888)],
    'pepsi': [Color(0xFF004B93), Color(0xFF0070CC), Color(0xFF66B5FF)],
    'orange-juice': [Color(0xFFFF6B00), Color(0xFFFFA500), Color(0xFFFFCC66)],
    'espresso': [Color(0xFF3E2723), Color(0xFF6D4C41), Color(0xFF8D6E63)],
    'chocolate-cake': [Color(0xFF4E342E), Color(0xFF795548), Color(0xFFA1887F)],
    'couscous': [Color(0xFFD4A373), Color(0xFFFAEDCD), Color(0xFFFEFAE0)],
  };

  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Primary Color Scheme
      primaryColor: primaryGreen,
      primaryColorLight: primaryGreenLight,
      primaryColorDark: primaryGreenDark,
      secondaryHeaderColor: secondaryOrange,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: secondaryOrange,
        tertiary: accentRed,
        error: error,
        surface: neutralWhite,
        onPrimary: neutralWhite,
        onSecondary: neutralWhite,
        onSurface: neutralBlack,
        onError: neutralWhite,
        brightness: Brightness.light,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: neutralLightGrey,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: neutralBlack,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutralBlack,
        ),
        iconTheme: IconThemeData(color: neutralBlack),
      ),

      // Typography
      fontFamily: 'Poppins',
      textTheme: const TextTheme(
        // Display Styles
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: neutralBlack,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: neutralBlack,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: neutralBlack,
        ),

        // Headline Styles
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: neutralBlack,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutralBlack,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralBlack,
        ),

        // Body Styles
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          height: 1.5,
          color: neutralBlack,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          height: 1.5,
          color: neutralBlack,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          height: 1.4,
          color: neutralGrey,
        ),

        // Label Styles
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: neutralBlack,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: neutralGrey,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryGreen),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutralWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutralGrey.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: neutralGrey),
        hintStyle: TextStyle(color: neutralGrey.withOpacity(0.7)),
      ),

      // ✅ FIXED: Card Theme - Changed from CardTheme to CardThemeData
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: neutralWhite,
        margin: const EdgeInsets.all(8),
      ),

      // ✅ FIXED: Dialog Theme - Changed from DialogTheme to DialogThemeData
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: neutralWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Navigation Bar Theme
      // ✅ FIXED: Navigation Bar Theme - removed 'shape' parameter
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        height: 60,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: primaryGreen.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: neutralGrey,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryGreen, size: 24);
          }
          return const IconThemeData(color: neutralGrey, size: 24);
        }),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: neutralLightGrey,
        thickness: 1,
        space: 16,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: neutralBlack,
        contentTextStyle: const TextStyle(color: neutralWhite),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        circularTrackColor: neutralLightGrey,
      ),

      // ✅ FIXED: Tab Bar Theme - Changed from TabBarTheme to TabBarThemeData
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryGreen,
        unselectedLabelColor: neutralGrey,
        indicatorColor: primaryGreen,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),

      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ============================================
  // DARK THEME (Optional)
  // ============================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      primaryColor: primaryGreenLight,
      primaryColorLight: primaryGreen,
      primaryColorDark: primaryGreenDark,
      secondaryHeaderColor: secondaryOrangeLight,

      colorScheme: const ColorScheme.dark(
        primary: primaryGreenLight,
        secondary: secondaryOrangeLight,
        tertiary: accentRed,
        error: error,
        surface: Color(0xFF1E1E1E),
        onPrimary: neutralWhite,
        onSecondary: neutralBlack,
        onSurface: neutralWhite,
        onError: neutralWhite,
        brightness: Brightness.dark,
      ),

      scaffoldBackgroundColor: const Color(0xFF121212),

      // ✅ FIXED: Card Theme for dark mode
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1E1E1E),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreenLight, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: neutralWhite),
        displayMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: neutralWhite),
        bodyLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            height: 1.5,
            color: neutralWhite),
        bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.5,
            color: Colors.white70),
      ),

      // ✅ FIXED: Dialog Theme for dark mode
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        backgroundColor: const Color(0xFF1E1E1E),
      ),

      // ✅ FIXED: Tab Bar Theme for dark mode
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryGreenLight,
        unselectedLabelColor: neutralGrey,
        indicatorColor: primaryGreenLight,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get dynamic gradient based on product brand or name
  static Gradient getProductGradient(
      String productName, List<String>? customColors) {
    if (customColors != null && customColors.length >= 2) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(int.parse(customColors[0].replaceFirst('#', '0xFF'))),
          Color(int.parse(customColors[1].replaceFirst('#', '0xFF'))),
        ],
      );
    }

    // Default gradients based on product name
    final key = productName.toLowerCase();
    if (key.contains('coca') || key.contains('cola')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCC0000), Color(0xFFFF4444)],
      );
    } else if (key.contains('pepsi')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF004B93), Color(0xFF0070CC)],
      );
    } else if (key.contains('orange') || key.contains('juice')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6B00), Color(0xFFFFA500)],
      );
    } else if (key.contains('coffee') || key.contains('espresso')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3E2723), Color(0xFF6D4C41)],
      );
    } else if (key.contains('chocolate') || key.contains('cake')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4E342E), Color(0xFF795548)],
      );
    } else if (key.contains('couscous') || key.contains('traditional')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD4A373), Color(0xFFFAEDCD)],
      );
    }

    // Default gradient
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryGreen, secondaryOrange],
    );
  }

  /// Get shimmer gradient for loading states
  static Gradient get shimmerGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEBEBEB),
          Color(0xFFF5F5F5),
          Color(0xFFEBEBEB),
        ],
        stops: [0.0, 0.5, 1.0],
      );

  /// Get glass morphic effect
  static BoxDecoration get glassMorphicDecoration => BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      );

  /// Get status color based on order status
  static Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return info;
      case 'confirmed':
        return primaryGreen;
      case 'preparing':
        return secondaryOrange;
      case 'on_the_way':
        return accentBlue;
      case 'delivered':
        return success;
      case 'cancelled':
        return error;
      default:
        return neutralGrey;
    }
  }
}
