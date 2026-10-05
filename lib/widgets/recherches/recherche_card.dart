import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/recherche.dart';

class RechercheCard extends StatelessWidget {
  final RechercheModel recherche;

  const RechercheCard({super.key, required this.recherche});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/recherches/${recherche.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kGreyBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Badge(label: recherche.typeBienAffiche, color: kViolet),
                    _Badge(
                      label: recherche.typeTransaction == 'location' ? 'Location' : 'Achat',
                      color: kGold,
                      textColor: kBlack,
                    ),
                    if (recherche.fondsDisponibles)
                      _Badge(label: 'Fonds disponibles', color: kGreen),
                  ],
                ),
                const SizedBox(height: 4),
                Text(AppFormatters.dateCourte(recherche.createdAt), style: AppText.cardMeta),
              ],
            ),
            const SizedBox(height: 10),

            // Titre
            Text(recherche.titre, style: AppText.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),

            // Description
            if (recherche.description != null && recherche.description!.isNotEmpty) ...[
              Text(
                recherche.description!,
                style: AppText.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
            ],

            // Localisation
            Row(
              children: [
                Icon(Icons.location_on, size: 13, color: kGrey),
                const SizedBox(width: 3),
                Text(
                  recherche.localisationImporte
                      ? 'Peu importe la localisation'
                      : [recherche.ville, recherche.quartier]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(', '),
                  style: AppText.cardMeta,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Budget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budget max', style: AppText.cardMeta),
                    Text(AppFormatters.fcfa(recherche.budgetMax), style: AppText.price.copyWith(fontSize: 16)),
                  ],
                ),
                // Contact rapide
                _ContactChip(telephone: recherche.auteurTelephone, whatsapp: recherche.auteurWhatsapp),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Auteur
            Row(
              children: [
                _Avatar(nom: recherche.auteurNom),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(recherche.auteurNom, style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                ),
                // if (recherche.nbChambres > 0)
                //   Text('${recherche.nbChambres} ch.', style: AppText.cardMeta),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({required this.label, required this.color, this.textColor = kWhite});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: AppText.badge.copyWith(color: color)),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final String telephone;
  final String whatsapp;

  const _ContactChip({required this.telephone, required this.whatsapp});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBtn(icon: Icons.phone, color: kGold),
        const SizedBox(width: 8),
        _IconBtn(icon: Icons.chat, color: kGreen),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBtn({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nom;

  const _Avatar({required this.nom});

  String get _initiales {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return nom.isNotEmpty ? nom[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
      child: Center(
        child: Text(_initiales, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kBlack)),
      ),
    );
  }
}
