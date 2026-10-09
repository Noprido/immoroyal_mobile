import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/bien.dart';

/// Pastille de statut : À jour (vert) / Retard (rouge) / Sans locataire (gris).
class StatutLoyerChip extends StatelessWidget {
  final BienModel bien;
  const StatutLoyerChip({super.key, required this.bien});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color couleur;
    if (bien.enRetard) {
      label = 'Retard · ${bien.joursRetard ?? 0} j';
      couleur = kRed;
    } else if (bien.aJour) {
      label = 'À jour';
      couleur = kActiveGreen;
    } else {
      label = 'Sans locataire';
      couleur = kGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: couleur),
          const SizedBox(width: 4),
          Text(label, style: AppText.badge.copyWith(color: couleur)),
        ],
      ),
    );
  }
}

/// Ligne cliquable d'un bien (nom, locataire, loyer, statut).
class BienTile extends StatelessWidget {
  final BienModel bien;
  final VoidCallback onTap;
  const BienTile({super.key, required this.bien, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final parties = <String>[
      bien.aLocataire ? (bien.locataireNom ?? 'Locataire') : 'Aucun locataire',
      if (bien.bail != null) AppFormatters.fcfa(bien.loyerMensuel),
    ];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kGreyLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_outlined, size: 20, color: kGrey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bien.nom, style: AppText.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    parties.join(' · '),
                    style: AppText.cardMeta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatutLoyerChip(bien: bien),
          ],
        ),
      ),
    );
  }
}
