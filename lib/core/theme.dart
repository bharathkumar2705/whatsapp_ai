import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand / Palette ────────────────────────────────────────────────────────
class AppColors {
  // Primary brand
  static const Color primary    = Color(0xFF00A884); // WhatsApp green (2024 brand)
  static const Color primaryDark= Color(0xFF017561);
  static const Color accent     = Color(0xFF25D366);

  // Light surface
  static const Color bgLight    = Color(0xFFF0F2F5);
  static const Color surfLight  = Colors.white;
  static const Color divLight   = Color(0xFFE9EDEF);
  static const Color textLight  = Color(0xFF111B21);
  static const Color subLight   = Color(0xFF667781);

  // Dark surface — WhatsApp official dark palette
  static const Color bgDark     = Color(0xFF0B141A);
  static const Color surfDark   = Color(0xFF1F2C33);
  static const Color surf2Dark  = Color(0xFF2A3942);
  static const Color divDark    = Color(0xFF2A3942);
  static const Color textDark   = Color(0xFFE9EDEF);
  static const Color subDark    = Color(0xFF8696A0);

  // Bubble colors
  static const Color bubbleOut  = Color(0xFFD9FDD3); // light outgoing
  static const Color bubbleOutD = Color(0xFF005C4B); // dark outgoing
  static const Color bubbleIn   = Colors.white;
  static const Color bubbleInD  = Color(0xFF1F2C33); // dark incoming

  // Status / semantic
  static const Color online     = Color(0xFF25D366);
  static const Color delivered  = Color(0xFF53BDEB);
  static const Color error      = Color(0xFFFF3B30);
}

// ─── Typography helper ───────────────────────────────────────────────────────
TextTheme _buildTextTheme(Color bodyColor, Color displayColor) {
  final base = GoogleFonts.interTextTheme();
  return base.copyWith(
    displayLarge:  base.displayLarge?.copyWith(color: displayColor, fontWeight: FontWeight.w700),
    displayMedium: base.displayMedium?.copyWith(color: displayColor, fontWeight: FontWeight.w700),
    headlineLarge: base.headlineLarge?.copyWith(color: displayColor, fontWeight: FontWeight.w700, fontSize: 22),
    headlineMedium:base.headlineMedium?.copyWith(color: displayColor, fontWeight: FontWeight.w600, fontSize: 18),
    titleLarge:    base.titleLarge?.copyWith(color: displayColor, fontWeight: FontWeight.w600, fontSize: 17),
    titleMedium:   base.titleMedium?.copyWith(color: bodyColor, fontWeight: FontWeight.w500, fontSize: 15),
    titleSmall:    base.titleSmall?.copyWith(color: bodyColor, fontWeight: FontWeight.w500, fontSize: 13),
    bodyLarge:     base.bodyLarge?.copyWith(color: bodyColor, fontSize: 15, height: 1.45),
    bodyMedium:    base.bodyMedium?.copyWith(color: bodyColor, fontSize: 14, height: 1.4),
    bodySmall:     base.bodySmall?.copyWith(color: bodyColor.withAlpha(178), fontSize: 12),
    labelLarge:    base.labelLarge?.copyWith(color: displayColor, fontWeight: FontWeight.w600, fontSize: 14),
    labelSmall:    base.labelSmall?.copyWith(color: bodyColor.withAlpha(153), fontSize: 11, letterSpacing: 0.4),
  );
}

// ─── Full Themes ─────────────────────────────────────────────────────────────
class AppTheme {
  // ── Light ──────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const cs = ColorScheme(
      brightness:     Brightness.light,
      primary:        AppColors.primary,
      onPrimary:      Colors.white,
      primaryContainer: Color(0xFFD1F7EC),
      onPrimaryContainer: AppColors.primaryDark,
      secondary:      AppColors.accent,
      onSecondary:    Colors.white,
      secondaryContainer: Color(0xFFCCF5DE),
      onSecondaryContainer: AppColors.primaryDark,
      surface:        AppColors.surfLight,
      onSurface:      AppColors.textLight,
      surfaceContainerHighest: AppColors.bgLight,
      error:          AppColors.error,
      onError:        Colors.white,
      outline:        AppColors.divLight,
      shadow:         Colors.black12,
    );

    return ThemeData(
      useMaterial3:        true,
      brightness:          Brightness.light,
      colorScheme:         cs,
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme:           _buildTextTheme(AppColors.textLight, AppColors.textLight),
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation:       0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),
      // Bottom nav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.subLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),
      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
      ),
      // Card
      cardTheme: const CardThemeData(
        color: AppColors.surfLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textLight,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13, color: AppColors.subLight,
        ),
        iconColor: AppColors.subLight,
      ),
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.subLight),
      ),
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgLight,
        selectedColor: AppColors.primary.withAlpha(30),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divLight,
        thickness: 0.5,
        space: 0,
      ),
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textLight,
        ),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.subLight),
      ),
      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 8,
      ),
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary.withAlpha(128) : Colors.grey.shade300),
      ),
      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      // Icon
      iconTheme: const IconThemeData(color: AppColors.subLight, size: 22),
      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }

  // ── Dark ───────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const cs = ColorScheme(
      brightness:     Brightness.dark,
      primary:        AppColors.primary,
      onPrimary:      Colors.white,
      primaryContainer: Color(0xFF004D3A),
      onPrimaryContainer: Color(0xFF8FF3D2),
      secondary:      AppColors.accent,
      onSecondary:    Colors.white,
      secondaryContainer: Color(0xFF004D22),
      onSecondaryContainer: Color(0xFF8FF7C2),
      surface:        AppColors.surfDark,
      onSurface:      AppColors.textDark,
      surfaceContainerHighest: AppColors.bgDark,
      error:          AppColors.error,
      onError:        Colors.white,
      outline:        AppColors.divDark,
      shadow:         Colors.black54,
    );

    return ThemeData(
      useMaterial3:        true,
      brightness:          Brightness.dark,
      colorScheme:         cs,
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme:           _buildTextTheme(AppColors.textDark, AppColors.textDark),
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfDark,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark, size: 22),
      ),
      // Bottom nav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.subDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),
      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.subDark,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
      ),
      // Card
      cardTheme: const CardThemeData(
        color: AppColors.surfDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13, color: AppColors.subDark,
        ),
        iconColor: AppColors.subDark,
      ),
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surf2Dark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.subDark),
      ),
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surf2Dark,
        selectedColor: AppColors.primary.withAlpha(50),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divDark,
        thickness: 0.5,
        space: 0,
      ),
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textDark,
        ),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.subDark),
      ),
      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 8,
      ),
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : AppColors.subDark),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary.withAlpha(128) : AppColors.surf2Dark),
      ),
      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      // Icon
      iconTheme: const IconThemeData(color: AppColors.subDark, size: 22),
      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
