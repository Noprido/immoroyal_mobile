import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/bien.dart';
import 'gestion_badge.dart';

/// Carte d'un bien : nom, lieu, locataire, loyer en doré, statut.
class BienCard extends StatelessWidget {
  final BienModel bien;
  final VoidCallback onTap;
  const BienCard({super.key, required this.bien, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lieu = [
      if (bien.quartier != null && bien.quartier!.isNotEmpty) bien.quartier!,
      bien.ville,
    ].join(', ');

    final GestionBadge badge;
    if (bien.enRetard) {
      badge = GestionBadge(label: 'Retard · ${bien.joursRetard ?? 0} j', couleur: kRed);
    } else if (bien.aJour) {
      badge = const GestionBadge(label: 'À jour', couleur: kActiveGreen);
    } else {
      badge = const GestionBadge(label: 'Sans locataire', couleur: kGrey);
    }

    return Material(
      color: kWhite,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kGreyBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.home_outlined, color: kGrey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bien.nom, style: AppText.cardTitle.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '$lieu · ${bien.aLocataire ? (bien.locataireNom ?? 'Locataire') : 'Aucun locataire'}',
                      style: AppText.cardMeta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bien.bail != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${AppFormatters.fcfa(bien.loyerMensuel)} / mois',
                        style: AppText.price.copyWith(fontSize: 13, letterSpacing: 0),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              badge,
            ],
          ),
        ),
      ),
    );
  }
}
