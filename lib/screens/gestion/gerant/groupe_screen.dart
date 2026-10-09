import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/gestion_provider.dart';
import '../../../widgets/gestion/bien_card.dart';
import '../../../widgets/gestion/groupe_card.dart';

/// Route hors shell : /gestion/groupes/:id — les biens d'un groupe.
class GroupeScreen extends StatelessWidget {
  final String groupeId;
  const GroupeScreen({super.key, required this.groupeId});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<GestionProvider>();
    final groupe = prov.groupeParId(groupeId);

    if (groupe == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(title: const Text('Groupe')),
        body: Center(child: Text('Groupe introuvable.', style: AppText.bodySmall)),
      );
    }

    final biens = prov.biensDuGroupe(groupe.id);
    final retards = biens.where((b) => b.enRetard).length;
    final total = biens.fold<double>(0, (s, b) => s + b.loyerMensuel);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(groupe.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          GroupeMenu(
            groupe: groupe,
            biens: biens,
            quitterApresSuppression: true,
            couleurIcone: kWhite,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: kGold,
        onRefresh: () => prov.load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
          children: [
            if (groupe.description != null && groupe.description!.isNotEmpty) ...[
              Text(groupe.description!, style: AppText.bodySmall.copyWith(height: 1.5)),
              const SizedBox(height: 12),
            ],
            Text(
              '${biens.length} bien${biens.length > 1 ? 's' : ''}'
              ' · ${(total / 1000).round()}k FCFA / mois'
              '${retards > 0 ? ' · $retards en retard' : ''}',
              style: AppText.cardMeta.copyWith(color: retards > 0 ? kRed : kGrey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (biens.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kGreyBorder),
                ),
                child: Text(
                  'Aucun bien dans ce groupe pour l\'instant.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySmall,
                ),
              )
            else
              for (final b in biens) ...[
                BienCard(bien: b, onTap: () => context.push('/gestion/biens/${b.id}')),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 6),
            ElevatedButton.icon(
              onPressed: () => context.push('/gestion/biens/creer?groupeId=${groupe.id}'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Ajouter un bien'),
            ),
          ],
        ),
      ),
    );
  }
}
