import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import 'pill_switcher.dart';

/// En-tête navy commun aux deux dashboards (libellé « Espace », titre, switcher
/// Gérant/Locataire pleine largeur, et bloc de stats optionnel).
class GestionHeader extends StatelessWidget {
  final String titre;
  final bool gerantActif;
  final ValueChanged<bool> onSwitch; // true = gérant, false = locataire
  final Widget? stats;

  const GestionHeader({
    super.key,
    required this.titre,
    required this.gerantActif,
    required this.onSwitch,
    this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kNavBar,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESPACE',
            style: AppText.badge.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$titre ', style: AppText.logoImmo.copyWith(fontSize: 24)),
                TextSpan(text: '·', style: AppText.logoRoyal.copyWith(fontSize: 24)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PillSwitcher(
            gerantActif: gerantActif,
            onGerant: () => onSwitch(true),
            onLocataire: () => onSwitch(false),
          ),
          if (stats != null) ...[
            const SizedBox(height: 14),
            stats!,
          ],
        ],
      ),
    );
  }
}

class StatItem {
  final String valeur;
  final String label;
  final Color couleur;
  const StatItem(this.valeur, this.label, {this.couleur = kGold});
}

/// Bloc de stats encadré : fond translucide, bordure, séparateurs verticaux.
class GestionStats extends StatelessWidget {
  final List<StatItem> items;
  const GestionStats({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final enfants = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) {
        enfants.add(Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.1)));
      }
      enfants.add(
        Expanded(
          child: Column(
            children: [
              Text(
                items[i].valeur,
                style: AppText.price.copyWith(fontSize: 20, letterSpacing: 0, color: items[i].couleur),
              ),
              const SizedBox(height: 3),
              Text(
                items[i].label,
                style: AppText.cardMeta.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(children: enfants),
    );
  }
}
