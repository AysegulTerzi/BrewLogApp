import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New Palette based on Modychat reference
  static const Color primaryColor = Color(0xFF1A1F36); // Deep Navy
  static const Color accentColor = Color(0xFFFF6B6B); // Coral/Pink
  static const Color backgroundColor = Color(0xFF1A1F36); // Matches primary
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF2D3142); // Dark Blue-Grey
  static const Color textOnPrimary = Colors.white;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        primary: primaryColor,
        secondary: accentColor,
        onPrimary: textOnPrimary,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textOnPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // For custom header look
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: false, // Left aligned title usually looks more modern
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textOnPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0, // Flat with border or subtle shadow looks cleaner
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F5F7), // Light grey for inputs
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.5)),
        hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 4,
          shadowColor: accentColor.withOpacity(0.4),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
