import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/bien.dart';
import '../../../providers/gestion_provider.dart';
import '../../../widgets/gestion/bien_tile.dart';
import '../../../widgets/gestion/confirm_dialog.dart';
import '../../../widgets/gestion/lier_locataire_sheet.dart';

/// Route hors shell : /gestion/biens/:id
class BienDetailScreen extends StatelessWidget {
  final String bienId;
  const BienDetailScreen({super.key, required this.bienId});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<GestionProvider>();
    final bien = prov.bienParId(bienId);

    if (bien == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(title: const Text('Bien')),
        body: Center(child: Text('Bien introuvable.', style: AppText.bodySmall)),
      );
    }

    final groupe = prov.groupeParId(bien.groupeId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(bien.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
        children: [
          _CarteInfos(bien: bien, groupeNom: groupe?.nom),
          const SizedBox(height: 12),
          _Actions(bien: bien),
          const SizedBox(height: 12),
          _CarteLoyer(bien: bien),
          const SizedBox(height: 12),
          _CarteLocataire(bien: bien),
        ],
      ),
    );
  }
}

// ─── Actions (toutes visibles, rien à chercher) ───────────────────

Future<void> _lier(BuildContext context, BienModel bien) {
  return LierLocataireSheet.show(context, bienId: bien.id, bienNom: bien.nom);
}

Future<void> _delier(BuildContext context, BienModel bien) async {
  final ok = await confirmerAction(
    context,
    titre: 'Délier le locataire ?',
    message: '${bien.locataireNom ?? 'Le locataire'} ne sera plus associé à « ${bien.nom} » '
        'et perdra l\'accès à ce logement dans son espace locataire.',
    confirmer: 'Délier',
  );
  if (!ok || !context.mounted) return;

  final prov = context.read<GestionProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final succes = await prov.delierLocataire(bien.id);
  messenger.showSnackBar(
    SnackBar(
      content: Text(succes ? 'Locataire délié' : (prov.error ?? 'Déliaison impossible')),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> _supprimer(BuildContext context, BienModel bien) async {
  final ok = await confirmerAction(
    context,
    titre: 'Supprimer ce bien ?',
    message: '« ${bien.nom} » sera supprimé définitivement, avec son bail et son historique.'
        '${bien.aLocataire ? '\n\nLe locataire lié sera délié.' : ''}'
        '\n\nCette action est irréversible.',
  );
  if (!ok || !context.mounted) return;

  final prov = context.read<GestionProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final succes = await prov.supprimerBien(bien.id);
  if (!context.mounted) return;

  if (succes) {
    context.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Bien supprimé'), behavior: SnackBarBehavior.floating),
    );
  } else {
    messenger.showSnackBar(
      SnackBar(content: Text(prov.error ?? 'Suppression impossible'), behavior: SnackBarBehavior.floating),
    );
  }
}

class _Actions extends StatelessWidget {
  final BienModel bien;
  const _Actions({required this.bien});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionBouton(
            icone: Icons.edit_outlined,
            label: 'Modifier',
            onTap: () => context.push('/gestion/biens/${bien.id}/modifier'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: bien.aLocataire
              ? _ActionBouton(
                  icone: Icons.person_remove_outlined,
                  label: 'Délier',
                  onTap: () => _delier(context, bien),
                )
              : _ActionBouton(
                  icone: Icons.person_add_alt_1_outlined,
                  label: 'Lier un locataire',
                  couleur: kGoldDark,
                  onTap: () => _lier(context, bien),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBouton(
            icone: Icons.delete_outline,
            label: 'Supprimer',
            couleur: kRed,
            onTap: () => _supprimer(context, bien),
          ),
        ),
      ],
    );
  }
}

class _ActionBouton extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color couleur;
  final VoidCallback onTap;

  const _ActionBouton({
    required this.icone,
    required this.label,
    required this.onTap,
    this.couleur = kBlack,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icone, size: 22, color: couleur),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.cardMeta.copyWith(fontWeight: FontWeight.w600, color: couleur),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cartes ───────────────────────────────────────────────────────

class _Carte extends StatelessWidget {
  final Widget child;
  const _Carte({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGreyBorder),
      ),
      child: child,
    );
  }
}

class _CarteInfos extends StatelessWidget {
  final BienModel bien;
  final String? groupeNom;
  const _CarteInfos({required this.bien, required this.groupeNom});

  @override
  Widget build(BuildContext context) {
    final lieu = [
      bien.adresse,
      if (bien.quartier != null && bien.quartier!.isNotEmpty) bien.quartier!,
      bien.ville,
    ].join(', ');

    return _Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(bien.nom, style: AppText.sectionTitle)),
              StatutLoyerChip(bien: bien),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: kGrey),
              const SizedBox(width: 6),
              Expanded(child: Text(lieu, style: AppText.bodySmall)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              bien.typeBien,
              if (groupeNom != null) 'Groupe : $groupeNom',
              if (bien.proprietaireNom != null && bien.proprietaireNom!.isNotEmpty)
                'Propriétaire : ${bien.proprietaireNom}',
            ].join(' · '),
            style: AppText.cardMeta,
          ),
        ],
      ),
    );
  }
}

class _CarteLoyer extends StatelessWidget {
  final BienModel bien;
  const _CarteLoyer({required this.bien});

  String _date(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final bail = bien.bail;

    if (bail == null) {
      return _Carte(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loyer', style: AppText.sectionTitle),
            const SizedBox(height: 6),
            Text('Aucun loyer défini pour ce bien.', style: AppText.bodySmall),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/gestion/biens/${bien.id}/modifier'),
              child: const Text('Définir le loyer'),
            ),
          ],
        ),
      );
    }

    return _Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loyer', style: AppText.sectionTitle),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppFormatters.fcfa(bail.montantLoyer), style: AppText.price),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('/ mois', style: AppText.priceUnit),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Échéance le ${bail.jourEcheance} de chaque mois', style: AppText.bodySmall),
          const SizedBox(height: 2),
          Text(
            bail.dateFin == null
                ? 'Depuis le ${_date(bail.dateDebut)} · durée indéterminée'
                : 'Du ${_date(bail.dateDebut)} au ${_date(bail.dateFin!)}',
            style: AppText.bodySmall,
          ),
          if (bien.enRetard) ...[
            const SizedBox(height: 10),
            Text(
              'En retard de ${bien.joursRetard ?? 0} jour${(bien.joursRetard ?? 0) > 1 ? 's' : ''}',
              style: AppText.bodyBold.copyWith(fontSize: 13, color: kRed),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteLocataire extends StatelessWidget {
  final BienModel bien;
  const _CarteLocataire({required this.bien});

  String _initiales(String nom) {
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first[0].toUpperCase();
    return (mots.first[0] + mots.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (!bien.aLocataire) {
      return _Carte(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Locataire', style: AppText.sectionTitle),
            const SizedBox(height: 6),
            Text(
              'Aucun locataire lié. Liez-le avec son ID ImmoRoyal ou son numéro de téléphone pour suivre ses loyers.',
              style: AppText.bodySmall.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _lier(context, bien),
              child: const Text('Lier un locataire'),
            ),
          ],
        ),
      );
    }

    final nom = bien.locataireNom ?? 'Locataire';
    return _Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Locataire', style: AppText.sectionTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                child: Text(
                  _initiales(nom),
                  style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom, style: AppText.cardTitle.copyWith(fontSize: 15)),
                    if (bien.locataireTel != null) ...[
                      const SizedBox(height: 2),
                      Text(bien.locataireTel!, style: AppText.cardMeta),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
