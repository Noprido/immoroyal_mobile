import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/network/dio_client.dart';
import '../../models/recherche.dart';
import '../../widgets/common/gold_button.dart';

class ProfileRecherchesScreen extends StatefulWidget {
  const ProfileRecherchesScreen({super.key});
  @override
  State<ProfileRecherchesScreen> createState() => _ProfileRecherchesScreenState();
}

class _ProfileRecherchesScreenState extends State<ProfileRecherchesScreen> {
  List<RechercheModel> _recherches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await DioClient.instance.get('/profile/recherches');
      final recherches = (res.data as List).map((j) => RechercheModel.fromJson(j)).toList();
      if (mounted) setState(() { _recherches = recherches; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(RechercheModel recherche) async {
    try {
      await DioClient.instance.post('/recherches/${recherche.id}/toggle');
      await _load();
    } catch (e) {}
  }

  Future<void> _supprimer(RechercheModel recherche) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la recherche'),
        content: const Text('Cette action est irréversible. Confirmer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await DioClient.instance.delete('/recherches/${recherche.id}');
      await _load();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: kNavBar,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new, color: kWhite, size: 20),
        ),
        title: Image.asset('assets/images/IMMOROYAL_4_1.png', height: 45, fit: BoxFit.contain),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_recherches.length} recherche${_recherches.length > 1 ? "s" : ""}',
                style: AppText.bodySmall.copyWith(color: const Color(0xFF888888)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : _recherches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: kGreyBorder),
                      const SizedBox(height: 16),
                      Text('Aucune recherche publiée', style: AppText.sectionTitle.copyWith(color: kGrey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/recherches/creer'),
                        icon: const Icon(Icons.add),
                        label: const Text('Créer une recherche'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: kGold,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recherches.length,
                    itemBuilder: (_, i) => _RechercheItem(
                      recherche: _recherches[i],
                      onVoir: () => context.push('/recherches/${_recherches[i].id}'),
                      onModifier: () => context.push('/recherches/${_recherches[i].id}/modifier'),
                      onToggle: () => _toggle(_recherches[i]),
                      onSupprimer: () => _supprimer(_recherches[i]),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recherches/creer'),
        backgroundColor: kGold,
        foregroundColor: kBlack,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RechercheItem extends StatelessWidget {
  final RechercheModel recherche;
  final VoidCallback onVoir, onModifier, onToggle, onSupprimer;

  const _RechercheItem({
    required this.recherche,
    required this.onVoir,
    required this.onModifier,
    required this.onToggle,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreyBorder),
      ),
      child: Column(
        children: [
          // ── Contenu ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges + statut
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
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
                            _Badge(label: 'Fonds dispo.', color: kGreen),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(actif: recherche.actif),
                  ],
                ),
                const SizedBox(height: 10),

                // Titre
                Text(recherche.titre, style: AppText.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),

                // Localisation
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: kGrey),
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
                const SizedBox(height: 6),

                // Budget + date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppFormatters.fcfa(recherche.budgetMax), style: AppText.price.copyWith(fontSize: 15)),
                    Text(AppFormatters.dateCourte(recherche.createdAt), style: AppText.cardMeta),
                  ],
                ),
              ],
            ),
          ),

          // ── Actions ──
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kGreyBorder)),
            ),
            child: Row(
              children: [
                _ActionBtn(icon: Icons.visibility_outlined, label: 'Voir', onTap: onVoir),
                _Divider(),
                _ActionBtn(icon: Icons.edit_outlined, label: 'Modifier', onTap: onModifier, color: kGold),
                _Divider(),
                _ActionBtn(
                  icon: recherche.actif ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  label: recherche.actif ? 'Désactiver' : 'Activer',
                  onTap: onToggle,
                  color: recherche.actif ? kGrey : kActiveGreen,
                ),
                _Divider(),
                _ActionBtn(icon: Icons.delete_outline, label: 'Supprimer', onTap: onSupprimer, color: kRed),
              ],
            ),
          ),
        ],
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: AppText.badge.copyWith(color: color)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool actif;
  const _StatusBadge({required this.actif});

  @override
  Widget build(BuildContext context) {
    final color = actif ? kActiveGreen : kGrey;
    final label = actif ? 'Active' : 'Inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = kBlack,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: kGreyBorder);
  }
}