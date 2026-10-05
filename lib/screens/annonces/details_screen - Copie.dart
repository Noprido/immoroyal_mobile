import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/api_constants.dart';
import '../../models/annonce.dart';
import '../../providers/auth_provider.dart';
import '../../services/annonces_service.dart';
import '../../widgets/common/gold_button.dart';
import '../../core/utils/guard_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class AnnonceDetailsScreen extends StatefulWidget {
  final String id;
  const AnnonceDetailsScreen({super.key, required this.id});
  @override
  State<AnnonceDetailsScreen> createState() => _AnnonceDetailsScreenState();
}

class _AnnonceDetailsScreenState extends State<AnnonceDetailsScreen> {
  final _service = AnnoncesService();
  AnnonceModel? _annonce;
  bool _loading = true;
  String? _error;
  bool _deleting = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final a = await _service.getAnnonce(widget.id);
      if (mounted) setState(() { _annonce = a; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Annonce introuvable.'; _loading = false; });
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

  Future<void> _supprimer() async {
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
    setState(() => _deleting = true);
    try {
      await _service.deleteAnnonce(widget.id);
      if (mounted) { HapticFeedback.mediumImpact(); context.go('/annonces'); }
    } catch (e) {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(
      backgroundColor: kWhite,
      body: Center(child: CircularProgressIndicator(color: kGold)),
    );
    if (_error != null) return Scaffold(
      appBar: AppBar(backgroundColor: kNavBar),
      body: Center(child: Text(_error!, style: AppText.body)),
    );

    final annonce = _annonce!;
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    final isOwner = context.read<AuthProvider>().user?.id == annonce.auteurId;
    final whatsapp = annonce.toJson()['auteurWhatsapp'] as String? ?? annonce.auteurTelephone;
    final hasMultiple = annonce.mediasUnifies.length > 1;

    return Scaffold(
      backgroundColor: kWhite,
      bottomNavigationBar: _ContactSticky(
        annonce: annonce,
        whatsapp: whatsapp,
        isOwner: isOwner,
        onAppeler: () => _appeler(annonce.auteurTelephone),
        onWhatsapp: () => _whatsapp(whatsapp),
        onMessage: () { if (guardAuth(context)) context.push('/messages/annonce/${annonce.id}'); },
      ),
      body: Stack(
        children: [
          // ── Contenu scrollable ──
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 300,
                pinned: false,
                floating: false,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image principale
                      annonce.mediasUnifies.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _openGallery(context, annonce.mediasUnifies, baseUrl, 0),
                              child: CachedNetworkImage(
                                imageUrl: '$baseUrl${annonce.mediasUnifies.first['url']}',
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: kGreyLight),
                                errorWidget: (_, __, ___) => Container(color: kGreyLight),
                              ),
                            )
                          : Container(color: kGreyLight),

                      // Overlay play si vidéo
                      if (annonce.mediasUnifies.isNotEmpty &&
                          annonce.mediasUnifies.first['type'] == 'video')
                        const IgnorePointer(
                          child: Center(
                            child: Icon(Icons.play_circle_fill, color: kWhite, size: 64),
                          ),
                        ),

                      // Gradient
                      const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x33000000), Color(0x80000000)],
                            ),
                          ),
                        ),
                      ),

                      // Bouton retour
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: kWhite, shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_back_ios_new, size: 18, color: kBlack),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bouton partage
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: kWhite, shape: BoxShape.circle),
                                child: const Icon(Icons.share_outlined, size: 18, color: kBlack),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Espace pour les miniatures en overlay
                    if (hasMultiple) const SizedBox(height: 52),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Badges ──
                          Row(
                            children: [
                              _Badge(annonce.typeBien, color: kGreyLight, textColor: kGrey),
                              const SizedBox(width: 8),
                              _Badge(
                                annonce.isLocation ? 'À louer' : 'À vendre',
                                color: kGoldBg, textColor: kGoldDark,
                                icon: Icons.vpn_key_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Titre ──
                          Text(annonce.titre, style: AppText.pageTitle.copyWith(fontSize: 22)),
                          const SizedBox(height: 8),

                          // ── Localisation ──
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 15, color: kGrey),
                              const SizedBox(width: 4),
                              Expanded(child: Text('${annonce.quartier}, ${annonce.ville}', style: AppText.bodySmall)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Prix ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(AppFormatters.fcfa(annonce.prixAffiche), style: AppText.priceLarge),
                              if (annonce.isLocation && annonce.dureeLocation != null) ...[
                                const SizedBox(width: 6),
                                Text(AppFormatters.getLabelDuree(annonce.dureeLocation), style: AppText.priceUnit),
                              ],
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),

                          // ── Infos financières ──
                          if (annonce.isLocation) ...[
                            _SectionTitle(icon: Icons.account_balance_wallet_outlined, label: 'Informations financières'),
                            const SizedBox(height: 12),
                            _InfoTable([
                              ('Loyer', AppFormatters.fcfa(annonce.prixAffiche)),
                              ('Durée', AppFormatters.getLabelDuree(annonce.dureeLocation)),
                              if (annonce.moisAvance > 0) ('Mois d\'avance', '${annonce.moisAvance} mois'),
                              if (annonce.cautionEau > 0) ('Caution eau', AppFormatters.fcfa(annonce.cautionEau)),
                              if (annonce.cautionElec > 0) ('Caution électricité', AppFormatters.fcfa(annonce.cautionElec)),
                              if (annonce.commissionDemarcheur > 0) ('Commission démarcheur', AppFormatters.fcfa(annonce.commissionDemarcheur)),
                            ]),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kGoldBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kGold.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total à prévoir à l\'entrée', style: AppText.bodyBold),
                                  Text(AppFormatters.fcfa(AppFormatters.totalEntree(annonce.toJson())), style: AppText.price.copyWith(fontSize: 16)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],

                          // ── Caractéristiques ──
                          if (!annonce.isTerrain && annonce.nbPieces > 0) ...[
                            _SectionTitle(icon: Icons.home_outlined, label: 'Caractéristiques'),
                            const SizedBox(height: 12),
                            _CaracteristiquesGrid(annonce: annonce),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],

                          // ── Description ──
                          if (annonce.description != null && annonce.description!.isNotEmpty) ...[
                            _SectionTitle(icon: Icons.description_outlined, label: 'Description'),
                            const SizedBox(height: 12),
                            Text(annonce.description!, style: AppText.body),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],

                          // ── Actions propriétaire ──
                          if (isOwner) ...[
                            GoldButton.outlined(
                              label: 'Modifier l\'annonce',
                              icon: Icons.edit_outlined,
                              onPressed: () => context.push('/annonces/${annonce.id}/modifier'),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _deleting ? null : _supprimer,
                                style: OutlinedButton.styleFrom(foregroundColor: kRed, side: const BorderSide(color: kRed)),
                                child: _deleting
                                    ? const CircularProgressIndicator(color: kRed, strokeWidth: 2)
                                    : const Text('Supprimer l\'annonce', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],

                          // ── Date ──
                          Text('Publié le ${AppFormatters.dateLocale(annonce.createdAt)}', style: AppText.bodySmall),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Miniatures en overlay par-dessus tout ──
          if (hasMultiple)
            Positioned(
              top: 268, // juste en dessous de l'image (300 - 32)
              left: 16,
              right: 16,
              child: _MiniatureStrip(
                medias: annonce.mediasUnifies,
                baseUrl: baseUrl,
              ),
            ),
        ],
      ),
    );
  }

  void _openGallery(BuildContext context, List<Map<String, String>> medias, String baseUrl, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _GalleryModal(medias: medias, initialIndex: index, baseUrl: baseUrl),
    ));
  }
}

// ─── Contact sticky ───────────────────────────────────────────────
class _ContactSticky extends StatelessWidget {
  final AnnonceModel annonce;
  final String whatsapp;
  final bool isOwner;
  final VoidCallback onAppeler, onWhatsapp, onMessage;

  const _ContactSticky({
    required this.annonce, required this.whatsapp, required this.isOwner,
    required this.onAppeler, required this.onWhatsapp, required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text('Contacter le propriétaire', style: AppText.bodyBold.copyWith(color: kWhite)),
            ],
          ),
          const SizedBox(height: 4),
          Text(annonce.auteurNom, style: AppText.label.copyWith(color: kGold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (isOwner)
            Text('C\'est votre annonce', style: AppText.bodySmall.copyWith(color: const Color(0xFF888888)))
          else
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onAppeler,
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
                          Text(annonce.auteurTelephone, style: const TextStyle(color: kGold, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onWhatsapp,
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
    );
  }
}

// ─── Miniature strip ──────────────────────────────────────────────
class _MiniatureStrip extends StatelessWidget {
  final List<Map<String, String>> medias;
  final String baseUrl;

  const _MiniatureStrip({required this.medias, required this.baseUrl});

  void _openGallery(BuildContext context, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _GalleryModal(medias: medias, initialIndex: index, baseUrl: baseUrl),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final visible = medias.take(5).toList();
    final extra = medias.length - 5;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(visible.length, (i) {
            final media = visible[i];
            final isLast = i == visible.length - 1 && extra > 0;
            final thumbUrl = '$baseUrl${media['url']}';
            final isVideo = media['type'] == 'video';

            return Padding(
              padding: EdgeInsets.only(right: i < visible.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => _openGallery(context, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56, height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: thumbUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: kGreyLight),
                          errorWidget: (_, __, ___) => Container(color: kGreyLight),
                        ),
                        if (isLast)
                          Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            child: Center(
                              child: Text('+$extra', style: const TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          )
                        else if (isVideo)
                          Container(
                            color: Colors.black.withValues(alpha: 0.2),
                            child: const Center(child: Icon(Icons.play_arrow, color: kWhite, size: 20)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Gallery modal ────────────────────────────────────────────────
class _GalleryModal extends StatefulWidget {
  final List<Map<String, String>> medias;
  final int initialIndex;
  final String baseUrl;

  const _GalleryModal({required this.medias, required this.initialIndex, required this.baseUrl});

  @override
  State<_GalleryModal> createState() => _GalleryModalState();
}

class _GalleryModalState extends State<_GalleryModal> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.medias.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final media = widget.medias[i];
              final isVideo = media['type'] == 'video';
              final photoUrl = '${widget.baseUrl}${media['url']}';
              final videoUrl = '${widget.baseUrl}${media['videoUrl'] ?? media['url']!}';
              return isVideo ? _VideoPlayer(url: videoUrl) : _PhotoViewer(url: photoUrl);
            },
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.close, color: kWhite, size: 22),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                  child: Text('${_current + 1} / ${widget.medias.length}', style: const TextStyle(color: kWhite, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),

          if (widget.medias.length > 1)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.medias.length.clamp(0, 10),
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _current ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _current ? kGold : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Photo viewer ─────────────────────────────────────────────────
class _PhotoViewer extends StatelessWidget {
  final String url;
  const _PhotoViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: kGold, strokeWidth: 2)),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: kGrey, size: 48),
        ),
      ),
    );
  }
}

// ─── Video player ─────────────────────────────────────────────────
class _VideoPlayer extends StatefulWidget {
  final String url;
  const _VideoPlayer({required this.url});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  VideoPlayerController? _vpCtrl;
  ChewieController? _chewieCtrl;
  bool _error = false;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    try {
      _vpCtrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _vpCtrl!.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _vpCtrl!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowedScreenSleep: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: kGold,
          handleColor: kGold,
          bufferedColor: kGold.withValues(alpha: 0.3),
          backgroundColor: Colors.white24,
        ),
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _vpCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: kGrey, size: 40),
          SizedBox(height: 8),
          Text('Impossible de lire la vidéo', style: TextStyle(color: kGrey)),
        ],
      ),
    );
    if (_chewieCtrl == null) return const Center(child: CircularProgressIndicator(color: kGold, strokeWidth: 2));
    return Chewie(controller: _chewieCtrl!);
  }
}

// ─── Composants UI ────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color, textColor;
  final IconData? icon;

  const _Badge(this.label, {required this.color, required this.textColor, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: textColor), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: kGold, margin: const EdgeInsets.only(right: 10)),
        Icon(icon, size: 18, color: kBlack),
        const SizedBox(width: 8),
        Text(label, style: AppText.sectionTitle.copyWith(fontSize: 16)),
      ],
    );
  }
}

class _InfoTable extends StatelessWidget {
  final List<(String, String)> rows;
  const _InfoTable(this.rows);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: kGreyBorder), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: kGreyBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.value.$1, style: AppText.bodySmall),
                Text(e.value.$2, style: AppText.bodyBold),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CaracteristiquesGrid extends StatelessWidget {
  final AnnonceModel annonce;
  const _CaracteristiquesGrid({required this.annonce});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[];
    if (annonce.nbPieces   > 0) items.add((Icons.grid_view,   '${annonce.nbPieces}',   'Pièces'));
    if (annonce.nbChambres > 0) items.add((Icons.king_bed,    '${annonce.nbChambres}', 'Chambres'));
    if (annonce.nbSalons   > 0) items.add((Icons.weekend,     '${annonce.nbSalons}',   'Salons'));
    if (annonce.nbDouches  > 0) items.add((Icons.shower,      '${annonce.nbDouches}',  'Douches'));
    if (annonce.nbCuisines > 0) items.add((Icons.restaurant,  '${annonce.nbCuisines}', 'Cuisines'));
    if (annonce.electriciteType != null) items.add((Icons.bolt, annonce.electriciteType == 'personnel' ? 'Perso.' : 'Commun', 'Électricité'));
    if (annonce.eauType != null) items.add((Icons.water_drop, annonce.eauType == 'personnel' ? 'Perso.' : 'Commun', 'Eau'));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.4,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.$1, size: 20, color: kGold),
              const SizedBox(height: 4),
              Text(item.$2, style: AppText.bodyBold.copyWith(fontSize: 16)),
              Text(item.$3, style: AppText.cardMeta),
            ],
          ),
        );
      },
    );
  }
}