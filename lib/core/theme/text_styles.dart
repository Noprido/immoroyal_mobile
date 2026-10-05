import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppText {
  AppText._();

  static TextStyle get pageTitle => GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w700, color: kBlack, height: 1.2);
  static TextStyle get pageTitleGold => GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w700, color: kGold, height: 1.2);
  static TextStyle get sectionTitle => GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: kBlack);
  static TextStyle get price => GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: kGold, letterSpacing: -0.5);
  static TextStyle get priceLarge => GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w800, color: kGold, letterSpacing: -1);
  static TextStyle get priceUnit => GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: kGrey);
  static TextStyle get body => GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w400, color: kBlack, height: 1.5);
  static TextStyle get bodySmall => GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: kGrey, height: 1.4);
  static TextStyle get bodyBold => GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: kBlack);
  static TextStyle get label => GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: kBlack);
  static TextStyle get labelGold => GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: kGold);
  static TextStyle get button => GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: kBlack, letterSpacing: 0.2);
  static TextStyle get buttonWhite => GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: kWhite, letterSpacing: 0.2);
  static TextStyle get badge => GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3);
  static TextStyle get cardTitle => GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: kBlack, height: 1.3);
  static TextStyle get cardMeta => GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: kGrey);
  static TextStyle get navLabel => GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500);

  // Logo navbar — gardé en RichText pour la version texte de fallback
  static TextStyle get logoImmo => GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: kWhite, letterSpacing: 0.5);
  static TextStyle get logoRoyal => GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: kGold, letterSpacing: 0.5);
}