import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/network/dio_client.dart';
import '../../models/recherche.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/guard_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/loading_shimmer.dart';

class RechercheDetailsScreen extends StatefulWidget {
  final String id;
  const RechercheDetailsScreen({super.key, required this.id});
  @override
  State<RechercheDetailsScreen> createState() => _RechercheDetailsScreenState();
}

class _RechercheDetailsScreenState extends State<RechercheDetailsScreen> {
  RechercheModel? _recherche;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await DioClient.instance.get('/recherches/${widget.id}');
      if (mounted) setState(() {
        _recherche = RechercheModel.fromJson(res.data as Map<String, dynamic>);
        _loading   = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Recherche introuvable.'; _loading = false; });
    }
  }

  Future<void> _appeler(String tel) async {
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _whatsapp(String wa) async {
    final number = wa.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(backgroundColor: kNavBar),
      body: const RechercheDetailSkeleton(),
    );
    
    if (_error != null) return Scaffold(appBar: AppBar(backgroundColor: kNavBar), body: Center(child: Text(_error!, style: AppText.body)));

    final r       = _recherche!;
    final isOwner = context.read<AuthProvider>().user?.id == r.auteurId;

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kNavBar,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new, color: kWhite, size: 20),
        ),
        title: const Text('Détail recherche', style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Badges ──
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(label: r.typeBienAffiche, color: kViolet),
                _Badge(
                  label: r.typeTransaction == 'location' ? 'Location' : 'Achat',
                  color: kGold, textColor: kBlack,
                ),
                if (r.fondsDisponibles) _Badge(label: 'Fonds disponibles', color: kGreen),
                _Badge(
                  label: r.actif ? 'Active' : 'Inactive',
                  color: r.actif ? kActiveGreen : kGrey,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Titre ──
            Text(r.titre, style: AppText.pageTitle.copyWith(fontSize: 22)),
            const SizedBox(height: 8),

            // ── Date ──
            Text('Publié le ${AppFormatters.dateLocale(r.createdAt)}', style: AppText.bodySmall),
            const SizedBox(height: 16),

            // ── Description ──
            if (r.description != null && r.description!.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 12),
              _SectionTitle(label: 'Description'),
              const SizedBox(height: 8),
              Text(r.description!, style: AppText.body),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 12),

            // ── Localisation ──
            _SectionTitle(label: 'Localisation'),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on,
              label: 'Zone',
              value: r.localisationImporte
                  ? 'Peu importe la localisation'
                  : [r.ville, r.quartier].where((s) => s != null && s.isNotEmpty).join(', '),
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 12),

            // ── Budget ──
            _SectionTitle(label: 'Budget'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kGoldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget maximum', style: AppText.bodyBold),
                  Text(AppFormatters.fcfa(r.budgetMax), style: AppText.price),
                ],
              ),
            ),
            if (r.typeTransaction == 'location' && r.dureeLocation != null) ...[
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.schedule, label: 'Durée', value: AppFormatters.getLabelDuree(r.dureeLocation)),
            ],
            const SizedBox(height: 16),

            // ── Caractéristiques ──
            if (r.nbChambres > 0 || r.nbSalons > 0 || r.nbDouches > 0 || r.nbCuisines > 0) ...[
              const Divider(),
              const SizedBox(height: 12),
              _SectionTitle(label: 'Caractéristiques souhaitées'),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: [
                  if (r.nbChambres > 0)  _CaracItem(icon: Icons.king_bed,   value: '${r.nbChambres}', label: 'Chambres'),
                  if (r.nbSalons > 0)    _CaracItem(icon: Icons.weekend,     value: '${r.nbSalons}',   label: 'Salons'),
                  if (r.nbDouches > 0)   _CaracItem(icon: Icons.shower,      value: '${r.nbDouches}',  label: 'Douches'),
                  if (r.nbCuisines > 0)  _CaracItem(icon: Icons.restaurant,  value: '${r.nbCuisines}', label: 'Cuisines'),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Actions propriétaire ──
            if (isOwner) ...[
              const Divider(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.push('/recherches/${r.id}/modifier');
                  _load();
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: kGold,
                  side: const BorderSide(color: kGold),
                ),
              ),
              const SizedBox(height: 100),
            ] else
              const SizedBox(height: 100),
          ],
        ),
      ),

      // ── Contact sticky ──
      bottomNavigationBar: isOwner
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: kDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -4))],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_pin, color: kGold, size: 18),
                      const SizedBox(width: 6),
                      Text('Contacter', style: AppText.bodyBold.copyWith(color: kWhite)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(r.auteurNom, style: AppText.label.copyWith(color: kGold, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _appeler(r.auteurTelephone),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              border: Border.all(color: kGold.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone, color: kGold, size: 18),
                                const SizedBox(width: 6),
                                Text(r.auteurTelephone, style: const TextStyle(color: kGold, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _whatsapp(r.auteurWhatsapp),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat, color: kWhite, size: 18),
                                SizedBox(width: 6),
                                Text('WhatsApp', style: TextStyle(color: kWhite, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: AppText.badge.copyWith(color: color)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: kGold, margin: const EdgeInsets.only(right: 10)),
        Text(label, style: AppText.sectionTitle.copyWith(fontSize: 15)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kGold),
        const SizedBox(width: 8),
        Text('$label : ', style: AppText.bodySmall),
        Expanded(child: Text(value, style: AppText.bodyBold)),
      ],
    );
  }
}

class _CaracItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _CaracItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: kGold),
          const SizedBox(height: 4),
          Text(value, style: AppText.bodyBold.copyWith(fontSize: 16)),
          Text(label, style: AppText.cardMeta),
        ],
      ),
    );
  }
}