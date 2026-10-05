import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/api_constants.dart';
import '../../models/annonce.dart';
import '../../models/user.dart';
import '../../core/network/dio_client.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePublicScreen extends StatefulWidget {
  final String id;
  const ProfilePublicScreen({super.key, required this.id});
  @override
  State<ProfilePublicScreen> createState() => _ProfilePublicScreenState();
}

class _ProfilePublicScreenState extends State<ProfilePublicScreen> {
  UserModel? _user;
  List<AnnonceModel> _annonces = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await DioClient.instance.get('/profile/public/${widget.id}');
      final data = res.data as Map<String, dynamic>;
      if (mounted) setState(() {
        _user     = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        _annonces = (data['annonces'] as List).map((j) => AnnonceModel.fromJson(j)).toList();
        _loading  = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Profil introuvable.'; _loading = false; });
    }
  }

  Future<void> _appeler() async {
    final uri = Uri.parse('tel:${_user!.telephone}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final number = _user!.whatsapp.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _copierLien() {
    final lien = '${ApiConstants.baseUrl.replaceAll('/api/v1', '')}/profile/public/${widget.id}';
    Clipboard.setData(ClipboardData(text: lien));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien copié !'), backgroundColor: kGold, duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: kWhite, body: Center(child: CircularProgressIndicator(color: kGold)));
    if (_error != null) return Scaffold(appBar: AppBar(backgroundColor: kNavBar), body: Center(child: Text(_error!, style: AppText.body)));

    final user    = _user!;
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');

    // Types de biens uniques
    final typesBiens = _annonces.map((a) => a.typeBien).toSet().toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Container(
              color: kNavBar,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Bouton retour
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kWhite.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new, color: kWhite, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Avatar
                    Container(
                      width: 72, height: 72,
                      decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          user.initiales,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kBlack),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nom
                    Text(user.nom, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kWhite)),
                    const SizedBox(height: 6),

                    // Type vendeur
                    if (user.typeVendeur != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: kWhite.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kWhite.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline, color: kGold, size: 13),
                            const SizedBox(width: 4),
                            Text(user.typeVendeur!, style: const TextStyle(fontSize: 12, color: kWhite)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Date membre
                    if (user.createdAt != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Color(0xFF888888), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'Membre depuis ${AppFormatters.dateLocale(user.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),

                    // Stats
                    Text(
                      '${_annonces.length} annonce${_annonces.length > 1 ? "s" : ""} active${_annonces.length > 1 ? "s" : ""}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    ),

                    // Bio
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          user.bio!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Boutons contact
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Appeler
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _appeler,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  border: Border.all(color: kGold.withValues(alpha: 0.6)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.phone, color: kGold, size: 18),
                                    const SizedBox(width: 8),
                                    Text(user.telephone, style: const TextStyle(color: kGold, fontSize: 14, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // WhatsApp
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _whatsapp,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: kGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat, color: kWhite, size: 18),
                                    SizedBox(width: 8),
                                    Text('WhatsApp', style: TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Copier lien
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _copierLien,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  border: Border.all(color: kWhite.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.link, color: kWhite, size: 18),
                                    SizedBox(width: 8),
                                    Text('Copier le lien', style: TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // ── Spécialisé en ──
          if (typesBiens.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: kWhite,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spécialisé en :', style: AppText.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: typesBiens.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kGoldBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kGold.withValues(alpha: 0.3)),
                        ),
                        child: Text(t, style: AppText.badge.copyWith(color: kGoldDark)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),

          // ── Annonces ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: 'Annonces de ', style: AppText.sectionTitle),
                        TextSpan(
                          text: user.nom.split(' ').first,
                          style: AppText.sectionTitle.copyWith(color: kGold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('${_annonces.length} publiées', style: AppText.bodySmall),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final annonce = _annonces[i];
                final thumb   = annonce.thumbnail;
                return GestureDetector(
                  onTap: () => context.push('/annonces/${annonce.id}'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kGreyBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 180, width: double.infinity,
                                child: thumb != null
                                    ? CachedNetworkImage(imageUrl: '$baseUrl$thumb', fit: BoxFit.cover, placeholder: (_, __) => Container(color: kGreyLight), errorWidget: (_, __, ___) => Container(color: kGreyLight))
                                    : Container(color: kGreyLight, child: const Icon(Icons.image_outlined, color: kGrey, size: 40)),
                              ),
                              // Badge type bien
                              Positioned(
                                top: 10, left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: kGold.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
                                  child: Text(annonce.typeBien, style: const TextStyle(color: kBlack, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              // Badge transaction
                              Positioned(
                                bottom: 10, left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: annonce.isLocation ? kGreen.withValues(alpha: 0.85) : kRed.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(annonce.isLocation ? Icons.vpn_key : Icons.swap_horiz, color: kWhite, size: 11),
                                      const SizedBox(width: 4),
                                      Text(annonce.isLocation ? 'À louer' : 'À vendre', style: const TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              if (annonce.hasVideo)
                                const Positioned(top: 10, right: 10, child: Icon(Icons.play_circle_fill, color: kWhite, size: 28)),
                            ],
                          ),
                        ),

                        // Infos
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(AppFormatters.fcfa(annonce.prixAffiche), style: AppText.price.copyWith(fontSize: 18)),
                                  if (annonce.isLocation && annonce.dureeLocation != null) ...[
                                    const SizedBox(width: 4),
                                    Text(AppFormatters.getLabelDuree(annonce.dureeLocation), style: AppText.priceUnit),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(annonce.titre, style: AppText.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 13, color: kGrey),
                                  const SizedBox(width: 3),
                                  Expanded(child: Text('${annonce.quartier}, ${annonce.ville}', style: AppText.cardMeta, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              if (annonce.nbPieces > 0 || annonce.nbDouches > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (annonce.nbPieces > 0) ...[
                                      const Icon(Icons.grid_view, size: 13, color: kGrey),
                                      const SizedBox(width: 3),
                                      Text('${annonce.nbPieces} pièces', style: AppText.cardMeta),
                                      const SizedBox(width: 12),
                                    ],
                                    if (annonce.nbDouches > 0) ...[
                                      const Icon(Icons.shower, size: 13, color: kGrey),
                                      const SizedBox(width: 3),
                                      Text('${annonce.nbDouches} douches', style: AppText.cardMeta),
                                    ],
                                    const Spacer(),
                                    Text(AppFormatters.dateCourte(annonce.createdAt), style: AppText.cardMeta.copyWith(color: kGold)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _annonces.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}