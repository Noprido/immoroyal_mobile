import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/annonce.dart';
import '../../core/constants/api_constants.dart';

class AnnonceCard extends StatelessWidget {
  final AnnonceModel annonce;
  final bool showActions; // true sur "Mes annonces"
  final VoidCallback? onModifier;
  final VoidCallback? onToggle;
  final VoidCallback? onSupprimer;

  const AnnonceCard({
    super.key,
    required this.annonce,
    this.showActions = false,
    this.onModifier,
    this.onToggle,
    this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/annonces/${annonce.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kGreyBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Miniature ──
            _Thumbnail(annonce: annonce),

            // ── Infos ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    annonce.titre,
                    style: AppText.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Type de bien (gris)
                  Text(annonce.typeBien, style: AppText.cardMeta),
                  const SizedBox(height: 6),

                  // Localisation
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 13, color: kGrey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${annonce.ville} · ${annonce.quartier}',
                          style: AppText.cardMeta,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Prix + Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppFormatters.fcfa(annonce.prixAffiche),
                        style: AppText.price.copyWith(fontSize: 16),
                      ),
                      Text(
                        AppFormatters.dateCourte(annonce.createdAt),
                        style: AppText.cardMeta,
                      ),
                    ],
                  ),

                  // Actions (Mes annonces)
                  if (showActions) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    _ActionRow(
                      annonce: annonce,
                      onModifier: onModifier,
                      onToggle: onToggle,
                      onSupprimer: onSupprimer,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final AnnonceModel annonce;
  const _Thumbnail({required this.annonce});

  @override
  Widget build(BuildContext context) {
    final thumb = annonce.thumbnail;
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Stack(
        children: [
          // Image / placeholder
          SizedBox(
            height: 170,
            width: double.infinity,
            child: thumb != null
                ? CachedNetworkImage(
                    imageUrl: '$baseUrl$thumb',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: kGreyLight),
                    errorWidget: (_, __, ___) => _PlaceholderThumb(),
                  )
                : _PlaceholderThumb(),
          ),

          // Badge vidéo
          if (annonce.hasVideo)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill, size: 14, color: kWhite),
                    SizedBox(width: 4),
                    Text('Vidéo', style: TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

          // Badge "En avant"
          if (annonce.enAvant)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:  kGold.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Color.fromARGB(255, 255, 215, 85),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'En vedette',
                            style: AppText.badge.copyWith(color: kWhite),
                          ),
                        ],
                      )
              ),
            ),
          // Badge type de bien (en haut à gauche)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:  kGold.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                annonce.typeBien,
                style: const TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Badge transaction (en bas à gauche)
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: annonce.isLocation
                          ? kGreen.withValues(alpha: 0.85) 
                          : kRed.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    annonce.isLocation ? Icons.vpn_key : Icons.swap_horiz,
                    color: kWhite,
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    annonce.isLocation ? 'À louer' : 'À vendre',
                    style: const TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: kGreyLight,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: kGrey),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final AnnonceModel annonce;
  final VoidCallback? onModifier;
  final VoidCallback? onToggle;
  final VoidCallback? onSupprimer;

  const _ActionRow({
    required this.annonce,
    this.onModifier,
    this.onToggle,
    this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Badge statut
        _StatusBadge(actif: annonce.actif, suspendu: annonce.suspendu),
        const Spacer(),

        // Voir
        _SmallBtn(
          icon: Icons.visibility_outlined,
          label: 'Voir',
          onTap: () => context.push('/annonces/${annonce.id}'),
        ),
        const SizedBox(width: 6),

        // Modifier
        _SmallBtn(
          icon: Icons.edit_outlined,
          label: 'Modifier',
          onTap: onModifier,
          color: kGold,
        ),
        const SizedBox(width: 6),

        // Activer / Désactiver
        _SmallBtn(
          icon: annonce.actif ? Icons.pause_circle_outline : Icons.play_circle_outline,
          label: annonce.actif ? 'Désactiver' : 'Activer',
          onTap: onToggle,
          color: annonce.actif ? kGrey : kActiveGreen,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool actif;
  final bool suspendu;
  const _StatusBadge({required this.actif, required this.suspendu});

  @override
  Widget build(BuildContext context) {
    final (label, color) = suspendu
        ? ('Suspendu', kSuspendedRed)
        : actif
            ? ('Actif', kActiveGreen)
            : ('Inactif', kGrey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppText.badge.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _SmallBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = kBlack,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppText.badge.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
