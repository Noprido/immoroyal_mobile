import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

/// Badge arrondi du module Gestion (fond clair opaque + texte coloré).
/// Ex : GestionBadge(label: 'À jour', couleur: kActiveGreen)
class GestionBadge extends StatelessWidget {
  final String label;
  final Color couleur;
  final IconData? icone;

  const GestionBadge({
    super.key,
    required this.label,
    required this.couleur,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        // Fond opaque : lisible aussi bien sur blanc que sur une image grise
        color: Color.alphaBlend(couleur.withValues(alpha: 0.12), kWhite),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 12, color: couleur),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppText.badge.copyWith(color: couleur)),
        ],
      ),
    );
  }
}
