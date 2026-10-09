import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/api_constants.dart';
import '../../models/annonce.dart';
import '../../models/recherche.dart';
import '../../providers/auth_provider.dart';
import '../../services/annonces_service.dart';
import '../../services/recherches_service.dart';
import '../../widgets/common/app_navbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

import '../../core/constants/app_config.dart';
import '../../core/cache/cache_service.dart';
import '../../widgets/common/loading_shimmer.dart';

class ProfileDashboardScreen extends StatefulWidget {
  const ProfileDashboardScreen({super.key});
  @override
  State<ProfileDashboardScreen> createState() => _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState extends State<ProfileDashboardScreen> {
  List<AnnonceModel> _annonces = [];
  List<RechercheModel> _recherches = [];
  int _nonLus = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    // Stale-while-revalidate
    if (!silent && AppConfig.persistanceActive) {
      final cached = CacheService.readMap(
        AppConfig.hiveBoxProfil,
        AppConfig.keyProfil,
      );
      if (cached != null) {
        _annonces   = (cached['annonces'] as List).map((j) => AnnonceModel.fromJson(j as Map<String, dynamic>)).toList();
        _recherches = (cached['recherches'] as List).map((j) => RechercheModel.fromJson(j as Map<String, dynamic>)).toList();
        _nonLus     = cached['nonLus'] as int? ?? 0;
        if (mounted) setState(() => _loading = false);
        silent = true;
      }
    }

    if (!silent && mounted) setState(() => _loading = true);

    try {
      final dio = DioClient.instance;
      final resAnnonces   = await dio.get('/profile/annonces');
      final resRecherches = await dio.get('/profile/recherches');
      final resMsgs       = await dio.get('/messages');

      final annonces   = (resAnnonces.data as List).map((j) => AnnonceModel.fromJson(j as Map<String, dynamic>)).toList();
      final recherches = (resRecherches.data as List).map((j) => RechercheModel.fromJson(j as Map<String, dynamic>)).toList();
      final nonLus     = (resMsgs.data as List).fold<int>(0, (sum, c) => sum + ((c['nonLus'] ?? 0) as int));

      if (AppConfig.persistanceActive) {
        await CacheService.saveMap(
          AppConfig.hiveBoxProfil,
          AppConfig.keyProfil,
          {
            'annonces':   resAnnonces.data,
            'recherches': resRecherches.data,
            'nonLus':     nonLus,
          },
        );
      }

      if (mounted) {
        setState(() {
          _annonces   = annonces;
          _recherches = recherches;
          _nonLus     = nonLus;
          _loading    = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return Scaffold(
        backgroundColor: kWhite,
        appBar: const ImmoRoyalAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Connectez-vous pour accéder à votre profil', style: AppText.body),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        color: kGold,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(child: _buildHeader(user)),

            // ── Stats ──
            SliverToBoxAdapter(child: _buildStats()),

            // ── Actions ──
            SliverToBoxAdapter(child: _buildActions(context)),

            // ── Mes dernières annonces ──
            SliverToBoxAdapter(child: _buildMesAnnonces(context)),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(user) {
    return Container(
      color: kNavBar,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
            child: Center(
              child: Text(
                user.initiales,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kBlack),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kWhite)),
                const SizedBox(height: 4),
                Text(user.telephone, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                if (user.typeVendeur != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: kGold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      user.typeVendeur!,
                      style: const TextStyle(fontSize: 11, color: kGold, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Bouton modifier
          GestureDetector(
            onTap: () => context.push('/profil/modifier'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kWhite.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined, color: kWhite, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final actives = _annonces.where((a) => a.actif && !a.suspendu).length;

    return Container(
      color: kNavBar,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kWhite.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kWhite.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            _StatItem(value: '${_annonces.length}', label: 'Annonces'),
            _Divider(),
            _StatItem(value: '$actives', label: 'Actives'),
            _Divider(),
            _StatItem(value: '$_nonLus', label: 'Messages', highlight: _nonLus > 0),
            _Divider(),
            _StatItem(value: '${_recherches.length}', label: 'Recherches'),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      color: kWhite,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // voir profil public
          _ActionTile(
            icon: Icons.person_outline,
            label: 'Mon profil public',
            onTap: () => context.push('/profil/public/${context.read<AuthProvider>().user?.id}'),
          ),
          const Divider(height: 1),
          // Mes annonces
          _ActionTile(
            icon: Icons.apartment_outlined,
            label: 'Toutes mes annonces',
            badge: _annonces.length,
            onTap: () => context.push('/profil/annonces'),
          ),
          const Divider(height: 1),
          // Mes recherches
          _ActionTile(
            icon: Icons.search_outlined,
            label: 'Mes recherches',
            badge: _recherches.length,
            onTap: () => context.push('/profil/recherches'),
          ),
          const Divider(height: 1),
          // Messages
          _ActionTile(
            icon: Icons.chat_bubble_outline,
            label: 'Messages',
            badge: _nonLus,
            badgeColor: kRed,
            onTap: () => context.go('/messages'),
          ),
          const Divider(height: 1),
          // Déconnexion
          _ActionTile(
            icon: Icons.logout,
            label: 'Se déconnecter',
            color: kRed,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(onPressed: () => context.pop(false), child: const Text('Annuler')),
                    TextButton(onPressed: () => context.pop(true), child: const Text('Déconnecter', style: TextStyle(color: kRed))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                context.go('/home');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMesAnnonces(BuildContext context) {
    
    if (_loading) return const ProfilDashboardSkeleton();
    if (_annonces.isEmpty) return const SizedBox.shrink();

    final baseUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    final dernieres = _annonces.take(3).toList();

    return Container(
      color: kWhite,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes dernières annonces', style: AppText.sectionTitle),
          const SizedBox(height: 14),
          ...dernieres.map((a) => _AnnonceRow(annonce: a, baseUrl: baseUrl)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/profil/annonces'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Voir toutes mes annonces', style: AppText.labelGold),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 14, color: kGold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets locaux ───────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value, label;
  final bool highlight;
  const _StatItem({required this.value, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: highlight ? kRed : kGold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: kWhite.withValues(alpha: 0.1));
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final Color color;
  final Color badgeColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
    this.color = kBlack,
    this.badgeColor = kGold,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: AppText.body.copyWith(color: color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
              ),
              child: Text('$badge', style: TextStyle(fontSize: 12, color: badgeColor, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 14, color: kGrey),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _AnnonceRow extends StatelessWidget {
  final AnnonceModel annonce;
  final String baseUrl;
  const _AnnonceRow({required this.annonce, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    final thumb = annonce.thumbnail;
    return GestureDetector(
      onTap: () => context.push('/annonces/${annonce.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: kGreyBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Miniature
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 70, height: 60,
                child: thumb != null
                    ? CachedNetworkImage(imageUrl: '$baseUrl$thumb', fit: BoxFit.cover, placeholder: (_, __) => Container(color: kGreyLight), errorWidget: (_, __, ___) => Container(color: kGreyLight))
                    : Container(color: kGreyLight, child: const Icon(Icons.image_outlined, color: kGrey)),
              ),
            ),
            const SizedBox(width: 10),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(annonce.titre, style: AppText.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${annonce.ville} · ${annonce.typeBien}', style: AppText.cardMeta, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(AppFormatters.fcfa(annonce.prixAffiche), style: AppText.price.copyWith(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Badge statut
            _StatusBadge(actif: annonce.actif, suspendu: annonce.suspendu),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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