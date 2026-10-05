import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

/// PLACEHOLDER — sera remplacé à l'étape 4 (détection des rôles,
/// onboarding, dashboards). Sert uniquement à faire compiler l'onglet.
class GestionShell extends StatelessWidget {
  const GestionShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: kNavBar,
        title: const Text(
          'Gestion immobilière',
          style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Text('Module Gestion — à venir', style: AppText.sectionTitle.copyWith(color: kGrey)),
      ),
    );
  }
}
