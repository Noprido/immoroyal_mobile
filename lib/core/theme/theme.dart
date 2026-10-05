import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: kWhite,
      colorScheme: const ColorScheme.light(
        primary: kGold,
        onPrimary: kBlack,
        secondary: kDark,
        onSecondary: kWhite,
        surface: kWhite,
        onSurface: kBlack,
        outline: kGreyBorder,
        error: kRed,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: kNavBar,
        foregroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black26,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: kWhite,
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kNavBar,
        selectedItemColor: kGold,
        unselectedItemColor: Color(0xFF888888),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),

      // InputDecoration (formulaires)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kGreyBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kGreyBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kRed, width: 1),
        ),
        labelStyle: GoogleFonts.dmSans(fontSize: 14, color: kGrey),
        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFFAAAAAA)),
        floatingLabelStyle: GoogleFonts.dmSans(fontSize: 12, color: kGold, fontWeight: FontWeight.w500),
      ),

      // ElevatedButton (bouton principal doré)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kGold,
          foregroundColor: kBlack,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      // OutlinedButton (bouton secondaire)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kGold,
          side: const BorderSide(color: kGold, width: 1.5),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kGold,
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: kWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: kGreyBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: kGreyBorder,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: kGreyLight,
        selectedColor: kGoldBg,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kGold,
        foregroundColor: kBlack,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }
}
