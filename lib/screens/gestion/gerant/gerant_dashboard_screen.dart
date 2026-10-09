import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/gestion_provider.dart';
import '../../../providers/locataire_provider.dart';
import '../../../widgets/gestion/gestion_header.dart';
import '../../../widgets/gestion/groupe_card.dart';
import '../../../widgets/gestion/groupe_dialog.dart';

/// Dashboard gérant : en-tête + switcher + stats, alerte précise, groupes compacts.
class GerantDashboardScreen extends StatelessWidget {
  final VoidCallback onSwitchLocataire;
  const GerantDashboardScreen({super.key, required this.onSwitchLocataire});

  Future<void> _ajouter(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.apartment_outlined, color: kGoldDark),
                title: Text('Nouveau groupe', style: AppText.bodyBold),
                subtitle: Text('Une résidence, un immeuble, un quartier…', style: AppText.cardMeta),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  GroupeDialog.show(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_home_outlined, color: kGoldDark),
                title: Text('Nouveau bien', style: AppText.bodyBold),
                subtitle: Text('Un appartement, une boutique, une maison…', style: AppText.cardMeta),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push('/gestion/biens/creer');
                },
              ),

              SizedBox(height: 100 + MediaQuery.of(context).padding.bottom)
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<GestionProvider>(
        builder: (_, prov, __) {
          final retards = [...prov.biensEnRetard]
            ..sort((a, b) => (b.joursRetard ?? 0).compareTo(a.joursRetard ?? 0));
          final vide = prov.groupes.isEmpty && prov.biens.isEmpty;

          return Column(
            children: [
              GestionHeader(
                titre: 'Gérant',
                gerantActif: true,
                onSwitch: (gerant) {
                  if (!gerant) onSwitchLocataire();
                },
                stats: GestionStats(items: [
                  StatItem('${prov.biens.length}', 'Biens'),
                  StatItem('${prov.groupes.length}', 'Groupes'),
                  StatItem('${retards.length}', 'En retard', couleur: retards.isEmpty ? kGold : kRed),
                  StatItem('${(prov.totalMensuel / 1000).round()}k', 'Loyers/mois'),
                ]),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: kGold,
                  onRefresh: () => prov.load(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 110 + MediaQuery.of(context).padding.bottom),
                    children: [
                      if (retards.isNotEmpty) ...[
                        _AlerteRetard(
                          nombre: retards.length,
                          nomPire: retards.first.nom,
                          jours: retards.first.joursRetard ?? 0,
                          onTap: () => context.push('/gestion/biens/${retards.first.id}'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mes groupes', style: AppText.sectionTitle),
                          GestureDetector(
                            onTap: () => GroupeDialog.show(context),
                            child: Text('+ Nouveau groupe', style: AppText.labelGold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (prov.groupes.isEmpty)
                        _CarteVide(onTap: () => GroupeDialog.show(context))
                      else
                        for (final g in prov.groupes) ...[
                          GroupeCard(key: ValueKey(g.id), groupe: g, biens: prov.biensDuGroupe(g.id)),
                          const SizedBox(height: 10),
                        ],
                      if (vide) ...[
                        const SizedBox(height: 14),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              context.read<GestionProvider>().reinitialiserChoix();
                              context.read<LocataireProvider>().reinitialiserChoix();
                            },
                            child: Text(
                              'Changer de rôle',
                              style: AppText.bodySmall.copyWith(decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80 + MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: () => _ajouter(context),
          backgroundColor: kGold,
          foregroundColor: kBlack,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _AlerteRetard extends StatelessWidget {
  final int nombre;
  final String nomPire;
  final int jours;
  final VoidCallback onTap;

  const _AlerteRetard({
    required this.nombre,
    required this.nomPire,
    required this.jours,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titre = nombre == 1 ? '1 loyer en retard' : '$nombre loyers en retard';
    final detail = '$nomPire · $jours jour${jours > 1 ? 's' : ''} de retard'
        '${nombre > 1 ? ' (+${nombre - 1} autre${nombre > 2 ? 's' : ''})' : ''}';

    return Material(
      color: kRed.withValues(alpha: 0.08),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: kRed.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: kRed, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: AppText.bodyBold.copyWith(fontSize: 14, color: kRed)),
                    const SizedBox(height: 2),
                    Text(detail, style: AppText.cardMeta.copyWith(color: kRed), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kRed),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteVide extends StatelessWidget {
  final VoidCallback onTap;
  const _CarteVide({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kGreyBorder),
        ),
        child: Column(
          children: [
            Text(
              'Aucun groupe pour l\'instant.\nCréez votre premier groupe (ex : une résidence), puis ajoutez-y vos biens.',
              textAlign: TextAlign.center,
              style: AppText.bodySmall.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Text('Créer un groupe', style: AppText.labelGold),
          ],
        ),
      ),
    );
  }
}
