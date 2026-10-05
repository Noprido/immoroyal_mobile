import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:immoroyal/core/constants/api_constants.dart';
import 'package:immoroyal/providers/auth_provider.dart';
import 'package:immoroyal/providers/messages_provider.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/app_config.dart';
import '../../core/cache/cache_service.dart';
import '../../models/message.dart';
import '../../widgets/common/loading_shimmer.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<ConversationModel> _conversations = [];
  List<ConversationModel> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filtrer);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().onConversationUpdated = () {
        if (mounted) _load(silent: true);
      };
    });
  }

  @override
  void dispose() {
    context.read<MessagesProvider>().onConversationUpdated = null;
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && _socket == null) {
      _connectSocket();
      auth.removeListener(_onAuthChanged);
    }
  }

  // @override
  // void dispose() {
  //   _searchCtrl.dispose();
  //   _socket?.disconnect();
  //   _socket?.dispose();
  //   super.dispose();
  // }

  void _filtrer() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _conversations
          : _conversations.where((c) =>
              (c.autreUserNom ?? '').toLowerCase().contains(q) ||
              (c.annoncetitre ?? '').toLowerCase().contains(q) ||
              (c.dernierMessageTexte ?? '').toLowerCase().contains(q),
            ).toList();
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && AppConfig.persistanceActive) {
      final cached = CacheService.read(
        AppConfig.hiveBoxConversations,
        AppConfig.keyConversations,
      );
      if (cached != null) {
        _conversations = cached.map((j) => ConversationModel.fromJson(j)).toList();
        _filtered = _conversations;
        if (mounted) setState(() => _loading = false);
        silent = true;
      }
    }

    if (!silent && mounted) setState(() => _loading = true);

    try {
      final res = await DioClient.instance.get('/messages');
      final list = res.data as List;

      if (AppConfig.persistanceActive) {
        await CacheService.save(
          AppConfig.hiveBoxConversations,
          AppConfig.keyConversations,
          list.map((e) => e as Map<String, dynamic>).toList(),
        );
      }

      final convs = list
          .map((j) => ConversationModel.fromJson(j as Map<String, dynamic>))
          .toList();

      if (mounted) setState(() {
        _conversations = convs;
        _filtered = convs;
        _loading = false;
      });
      _filtrer();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _connectSocket() {
    final token = context.read<AuthProvider>().token;

    _socket = IO.io(
      ApiConstants.baseUrl.replaceAll('/api/v1', ''),
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.on('conversation_updated', (data) {
      debugPrint('🔔 conversation_updated reçu : $data');
      _load(silent: true);
    });

    _socket!.on('messages_read', (data) {
      debugPrint('🔔 messages_read reçu : $data');
      _load(silent: true);
    });

    _socket!.onConnect((_) => debugPrint('✅ Socket ConversationsScreen connecté'));
    _socket!.onConnectError((e) => debugPrint('❌ Socket erreur : $e'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: kNavBar,
        title: RichText(
          text: const TextSpan(children: [
            TextSpan(text: 'Mes ', style: TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.w700)),
            TextSpan(text: 'messages', style: TextStyle(color: kGold, fontSize: 20, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      body: Column(
        children: [
          // ── Barre de recherche ──
          Container(
            color: kNavBar,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: kWhite.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kWhite.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, color: kWhite.withValues(alpha: 0.5), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: kWhite, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une conversation...',
                        hintStyle: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 14),
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchCtrl.clear(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(Icons.close, color: kWhite.withValues(alpha: 0.5), size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Liste ──
          Expanded(
            child: _loading
                ? const ConversationListSkeleton()
                : _filtered.isEmpty
                    ? _EmptyState(hasSearch: _searchCtrl.text.isNotEmpty)
                    : RefreshIndicator(
                        color: kGold,
                        onRefresh: () => _load(),
                        child: ListView.separated(
                          padding: EdgeInsets.only(bottom: 100 + MediaQuery.of(context).padding.bottom),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, indent: 80, color: kGreyBorder),
                          itemBuilder: (_, i) => _ConversationTile(
                            conversation: _filtered[i],
                            onTap: () => context.push('/messages/${_filtered[i].id}'),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.chat_bubble_outline,
            size: 64, color: kGreyBorder,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'Aucun résultat' : 'Aucune conversation',
            style: AppText.sectionTitle.copyWith(color: kGrey),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Essayez un autre terme'
                : 'Contactez un propriétaire depuis une annonce',
            style: AppText.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Tile conversation ────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.nonLus > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: hasUnread ? kGoldBg : kWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ──
            Stack(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: hasUnread ? kGold : kGreyLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initiales(conversation.autreUserNom ?? '?'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: hasUnread ? kBlack : kGrey,
                      ),
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          conversation.nonLus > 99 ? '99+' : '${conversation.nonLus}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: kWhite),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Infos ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.autreUserNom ?? 'Inconnu',
                          style: AppText.bodyBold.copyWith(
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppFormatters.dateCourte(conversation.dernierMessageDate),
                        style: AppText.cardMeta.copyWith(
                          color: hasUnread ? kGold : kGrey,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Titre annonce en or
                  if (conversation.annoncetitre != null)
                    Row(
                      children: [
                        const Icon(Icons.home_outlined, size: 11, color: kGold),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            conversation.annoncetitre!,
                            style: AppText.cardMeta.copyWith(
                              color: kGold,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),

                  // Dernier message
                  Text(
                    conversation.dernierMessageTexte ?? 'Aucun message',
                    style: AppText.cardMeta.copyWith(
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                      color: hasUnread ? kBlack : kGrey,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            // Icon(
            //   Icons.arrow_forward_ios,
            //   size: 13,
            //   color: hasUnread ? kGold : kGrey,
            // ),
          ],
        ),
      ),
    );
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return nom.isNotEmpty ? nom[0].toUpperCase() : '?';
  }
}