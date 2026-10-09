import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/bien.dart';
import '../../models/groupe.dart';
import '../../providers/gestion_provider.dart';
import 'confirm_dialog.dart';
import 'gestion_badge.dart';
import 'groupe_dialog.dart';

/// Suppression d'un groupe avec confirmation détaillée. Retourne true si supprimé.
Future<bool> supprimerGroupeAvecConfirmation(
  BuildContext context,
  GroupeModel g,
  List<BienModel> biens,
) async {
  final nbLies = biens.where((b) => b.aLocataire).length;
  final String message;
  if (biens.isEmpty) {
    message = 'Supprimer le groupe « ${g.nom} » ?';
  } else {
    message = 'Le groupe « ${g.nom} » et ses ${biens.length} bien${biens.length > 1 ? 's' : ''} '
        'seront supprimés définitivement, avec leurs baux et leur historique.'
        '${nbLies > 0 ? '\n\n$nbLies bien${nbLies > 1 ? 's ont' : ' a'} un locataire lié : il sera délié.' : ''}'
        '\n\nCette action est irréversible.';
  }

  final ok = await confirmerAction(context, titre: 'Supprimer ce groupe ?', message: message);
  if (!ok || !context.mounted) return false;

  final prov = context.read<GestionProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final succes = await prov.supprimerGroupe(g.id);
  messenger.showSnackBar(
    SnackBar(
      content: Text(succes ? 'Groupe supprimé' : (prov.error ?? 'Suppression impossible')),
      behavior: SnackBarBehavior.floating,
    ),
  );
  return succes;
}

/// Menu ⋮ d'un groupe (réutilisé par la carte et par l'écran du groupe).
class GroupeMenu extends StatelessWidget {
  final GroupeModel groupe;
  final List<BienModel> biens;
  final bool quitterApresSuppression;
  final Color couleurIcone;

  const GroupeMenu({
    super.key,
    required this.groupe,
    required this.biens,
    this.quitterApresSuppression = false,
    this.couleurIcone = kGrey,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: couleurIcone),
      tooltip: 'Actions du groupe',
      color: kWhite,
      onSelected: (action) async {
        switch (action) {
          case 'bien':
            context.push('/gestion/biens/creer?groupeId=${groupe.id}');
            break;
          case 'modifier':
            GroupeDialog.show(context, groupe: groupe);
            break;
          case 'supprimer':
            final ok = await supprimerGroupeAvecConfirmation(context, groupe, biens);
            if (ok && quitterApresSuppression && context.mounted) context.pop();
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'bien', child: _MenuLigne(icone: Icons.add_home_outlined, label: 'Ajouter un bien')),
        PopupMenuItem(value: 'modifier', child: _MenuLigne(icone: Icons.edit_outlined, label: 'Modifier le groupe')),
        PopupMenuItem(
          value: 'supprimer',
          child: _MenuLigne(icone: Icons.delete_outline, label: 'Supprimer le groupe', couleur: kRed),
        ),
      ],
    );
  }
}

/// Carte compacte d'un groupe : icône, nom, « N biens · Ville », badge, chevron.
/// Un tap ouvre l'écran du groupe.
class GroupeCard extends StatelessWidget {
  final GroupeModel groupe;
  final List<BienModel> biens;

  const GroupeCard({super.key, required this.groupe, required this.biens});

  @override
  Widget build(BuildContext context) {
    final retards = biens.where((b) => b.enRetard).length;
    final villes = biens.map((b) => b.ville).where((v) => v.isNotEmpty).toSet().toList();
    final meta = [
      '${biens.length} bien${biens.length > 1 ? 's' : ''}',
      if (villes.isNotEmpty) villes.first,
    ].join(' · ');

    final GestionBadge badge;
    if (retards > 0) {
      badge = GestionBadge(label: '$retards retard${retards > 1 ? 's' : ''}', couleur: kRed);
    } else if (biens.any((b) => b.aLocataire)) {
      badge = const GestionBadge(label: 'À jour', couleur: kActiveGreen);
    } else {
      badge = const GestionBadge(label: 'Aucun locataire', couleur: kGrey);
    }

    return Material(
      color: kWhite,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kGreyBorder),
      ),
      child: InkWell(
        onTap: () => context.push('/gestion/groupes/${groupe.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: kGoldBg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.apartment_outlined, color: kGoldDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groupe.nom, style: AppText.cardTitle.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(meta, style: AppText.cardMeta, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              badge,
              const Icon(Icons.chevron_right, color: kGreyBorder, size: 22),
              GroupeMenu(groupe: groupe, biens: biens),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuLigne extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color couleur;
  const _MenuLigne({required this.icone, required this.label, this.couleur = kBlack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 18, color: couleur),
        const SizedBox(width: 10),
        Text(label, style: AppText.body.copyWith(fontSize: 14, color: couleur)),
      ],
    );
  }
}
