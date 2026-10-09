import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

/// Bascule Gérant / Locataire pleine largeur, à placer dans l'en-tête navy
/// (voir GestionHeader). Fond translucide arrondi, option active en doré.
class PillSwitcher extends StatelessWidget {
  final bool gerantActif;
  final VoidCallback onGerant;
  final VoidCallback onLocataire;

  const PillSwitcher({
    super.key,
    required this.gerantActif,
    required this.onGerant,
    required this.onLocataire,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: PillOption(label: 'Gérant', isActive: gerantActif, onTap: onGerant)),
          Expanded(child: PillOption(label: 'Locataire', isActive: !gerantActif, onTap: onLocataire)),
        ],
      ),
    );
  }
}

class PillOption extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const PillOption({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? kGold : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: AppText.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? kBlack : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
