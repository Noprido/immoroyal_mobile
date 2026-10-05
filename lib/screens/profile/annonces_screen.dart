import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/api_constants.dart';
import '../../models/annonce.dart';
import '../../services/annonces_service.dart';
import '../../widgets/common/app_navbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/network/dio_client.dart';

class ProfileAnnoncesScreen extends StatefulWidget {
  const ProfileAnnoncesScreen({super.key});
  @override
  State<ProfileAnnoncesScreen> createState() => _ProfileAnnoncesScreenState();
}

class _ProfileAnnoncesScreenState extends State<ProfileAnnoncesScreen> {
  final _service = AnnoncesService();
  List<AnnonceModel> _annonces = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = DioClient.instance;
      final res = await dio.get('/profile/annonces');
      final annonces = (res.data as List).map((j) => AnnonceModel.fromJson(j)).toList();
      if (mounted) setState(() { _annonces = annonces; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(AnnonceModel annonce) async {
    try {
      await _service.toggleActif(annonce.id);
      await _load();
    } catch (e) {}
  }

  Future<void> _supprimer(AnnonceModel annonce) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: const Text('Cette action est irréversible. Confirmer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteAnnonce(annonce.id);
      await _load();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');

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
                '${_annonces.length} annonce${_annonces.length > 1 ? "s" : ""}',
                style: AppText.bodySmall.copyWith(color: const Color(0xFF888888)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : _annonces.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.apartment_outlined, size: 64, color: kGreyBorder),
                      const SizedBox(height: 16),
                      Text('Aucune annonce publiée', style: AppText.sectionTitle.copyWith(color: kGrey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/annonces/creer'),
                        icon: const Icon(Icons.add),
                        label: const Text('Publier une annonce'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: kGold,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _annonces.length,
                    itemBuilder: (_, i) => _AnnonceItem(
                      annonce: _annonces[i],
                      baseUrl: baseUrl,
                      onVoir: () => context.push('/annonces/${_annonces[i].id}'),
                      onModifier: () => context.push('/annonces/${_annonces[i].id}/modifier'),
                      onToggle: () => _toggle(_annonces[i]),
                      onSupprimer: () => _supprimer(_annonces[i]),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/annonces/creer'),
        backgroundColor: kGold,
        foregroundColor: kBlack,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AnnonceItem extends StatelessWidget {
  final AnnonceModel annonce;
  final String baseUrl;
  final VoidCallback onVoir, onModifier, onToggle, onSupprimer;

  const _AnnonceItem({
    required this.annonce,
    required this.baseUrl,
    required this.onVoir,
    required this.onModifier,
    required this.onToggle,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = annonce.thumbnail;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreyBorder),
      ),
      child: Column(
        children: [
          // ── Ligne principale ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Miniature
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 72, height: 64,
                    child: thumb != null
                        ? CachedNetworkImage(
                            imageUrl: '$baseUrl$thumb',
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: kGreyLight),
                            errorWidget: (_, __, ___) => Container(color: kGreyLight),
                          )
                        : Container(color: kGreyLight, child: const Icon(Icons.image_outlined, color: kGrey)),
                  ),
                ),
                const SizedBox(width: 12),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(annonce.titre, style: AppText.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text('${annonce.typeBien} · ${annonce.ville}', style: AppText.cardMeta, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(AppFormatters.fcfa(annonce.prixAffiche), style: AppText.price.copyWith(fontSize: 14)),
                          const Spacer(),
                          _StatusBadge(actif: annonce.actif, suspendu: annonce.suspendu),
                        ],
                      ),
                    ],
                  ),
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
                if (!annonce.suspendu) ...[
                  _ActionBtn(
                    icon: annonce.actif ? Icons.pause_circle_outline : Icons.play_circle_outline,
                    label: annonce.actif ? 'Désactiver' : 'Activer',
                    onTap: onToggle,
                    color: annonce.actif ? kGrey : kActiveGreen,
                  ),
                  _Divider(),
                ],
                _ActionBtn(icon: Icons.delete_outline, label: 'Supprimer', onTap: onSupprimer, color: kRed),
              ],
            ),
          ),
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

class _StatusBadge extends StatelessWidget {
  final bool actif, suspendu;
  const _StatusBadge({required this.actif, required this.suspendu});

  @override
  Widget build(BuildContext context) {
    final (label, color) = suspendu
        ? ('Suspendu', kRed)
        : actif
            ? ('Actif', kActiveGreen)
            : ('Inactif', kGrey);

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