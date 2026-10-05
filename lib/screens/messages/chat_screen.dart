import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:immoroyal/providers/messages_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:record/record.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ─── États audio ──────────────────────────────────────────────────
enum _AudioState { idle, recording, preview }

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _recorder   = AudioRecorder();
  final _picker     = ImagePicker();
  final _previewPlayer = ja.AudioPlayer();

  ConversationModel? _conversation;
  List<MessageModel> _messages = [];
  bool _loading  = true;
  bool _sending  = false;

  // Audio
  _AudioState _audioState = _AudioState.idle;
  int  _recordSeconds = 0;
  int  _recordDuration = 0;
  String? _recordPath;
  IO.Socket? _socket;
  Timer? _recordTimer;
  bool _previewPlaying = false;
  Duration _previewPosition = Duration.zero;
  Duration _previewTotal = Duration.zero;

  // Médias en attente
  List<XFile> _mediasEnAttente = [];

  @override
  void initState() {
    super.initState();
    _load();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().joinConversation(
        widget.conversationId,
        onMessage: (data) {
          final msg = MessageModel.fromJson(data);
          if (mounted) {
            setState(() => _messages.add(msg));
            _scrollToBottom();
            // Marquer lu immédiatement
            context.read<MessagesProvider>().markAsRead(widget.conversationId);
          }
        },
      );
    });

    _previewPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _previewPosition = p);
    });
    _previewPlayer.durationStream.listen((d) {
      if (mounted) setState(() => _previewTotal = d ?? Duration.zero);
    });
    _previewPlayer.playerStateStream.listen((s) {
      if (mounted) setState(() => _previewPlaying = s.playing);
      if (s.processingState == ja.ProcessingState.completed) {
        _previewPlayer.seek(Duration.zero);
        if (mounted) setState(() => _previewPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    context.read<MessagesProvider>().leaveConversation(widget.conversationId);
    _recordTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final res = await DioClient.instance.get('/messages/conversation/${widget.conversationId}');
      final data = res.data as Map<String, dynamic>;
      final conv = ConversationModel.fromJson(data['conversation'] as Map<String, dynamic>);
      final msgs = (data['messages'] as List)
          .map((j) => MessageModel.fromJson(j as Map<String, dynamic>))
          .toList();

      if (mounted) {setState(() {
        _conversation = conv;
        _messages     = msgs;
        if (!silent) _loading = false;
      });}

      if (!silent) _scrollToBottom();

      if (!silent) {
        context.read<MessagesProvider>().markAsRead(widget.conversationId);
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  // void _connectSocket() {
  //   final token = context.read<AuthProvider>().token; // adapte selon ton AuthProvider

  //   _socket = IO.io(
  //     ApiConstants.baseUrl.replaceAll('/api/v1', ''),
  //     IO.OptionBuilder()
  //       .setTransports(['websocket'])
  //       .disableAutoConnect()
  //       .setAuth({'token': token})
  //       .build(),
  //   );

  //   _socket!.connect();

  //   _socket!.onConnect((_) {
  //     _socket!.emit('join_conversation', widget.conversationId);
  //   });

  //   _socket!.on('new_message', (data) {
  //     final msg = MessageModel.fromJson(Map<String, dynamic>.from(data));
  //     if (mounted) {
  //       setState(() => _messages.add(msg));
  //       _scrollToBottom();
  //     }
  //   });

  //   _socket!.onDisconnect((_) {});

  //   _socket!.onConnectError((err) {
  //     // Fallback silencieux — on recharge une fois
  //     _load(silent: true);
  //   });
  // }

  // scroller vers le bas
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0, // 0 car la liste est en reverse: true
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Envoi texte ──
  Future<void> _envoyer() async {
    final texte = _msgCtrl.text.trim();
    if (texte.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await DioClient.instance.post(
        '/messages/conversation/${widget.conversationId}/send',
        data: {'texte': texte},
      );
      await _load(silent: true);
      _scrollToBottom();
    } catch (_) {
      _msgCtrl.text = texte;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Sélection médias ──
  Future<void> _ouvrirSelecteurMedia() async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined, color: kGold),
              title: const Text('Photos'),
              onTap: () async {
                Navigator.pop(context);
                final files = await _picker.pickMultiImage();
                if (files.isNotEmpty) {
                  setState(() => _mediasEnAttente.addAll(files));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: kGold),
              title: const Text('Vidéo'),
              onTap: () async {
                Navigator.pop(context);
                final f = await _picker.pickVideo(source: ImageSource.gallery);
                if (f != null) setState(() => _mediasEnAttente.add(f));
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Envoi médias en attente ──
  Future<void> _envoyerMedias() async {
    if (_mediasEnAttente.isEmpty) return;
    setState(() => _sending = true);
    try {
      for (final media in _mediasEnAttente) {
        final file = await MultipartFile.fromFile(media.path, filename: media.name);
        final formData = FormData.fromMap({'fichier': file});
        await DioClient.instance.post(
          '/messages/conversation/${widget.conversationId}/send-media',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
      }
      setState(() => _mediasEnAttente.clear());
      await _load(silent: true);
      _scrollToBottom();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Enregistrement vocal ──
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final path = '${Directory.systemTemp.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() { _audioState = _AudioState.recording; _recordSeconds = 0; _recordPath = path; });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordTimer?.cancel();
    _recordDuration = _recordSeconds;
    final path = await _recorder.stop();
    if (cancel || path == null) {
      setState(() { _audioState = _AudioState.idle; _recordSeconds = 0; _recordPath = null; });
      return;
    }
    _recordPath = path;
    await _previewPlayer.setFilePath(path);
    setState(() { _audioState = _AudioState.preview; _recordSeconds = 0; });
  }

  Future<void> _envoyerAudio() async {
    final path = _recordPath;
    if (path == null) return;
    await _previewPlayer.stop();
    setState(() { _audioState = _AudioState.idle; _sending = true; });
    try {
      final file = await MultipartFile.fromFile(path, filename: 'audio.m4a');
      final formData = FormData.fromMap({'audio': file, 'duree': _recordDuration.toString()});
      await DioClient.instance.post(
        '/messages/conversation/${widget.conversationId}/send-audio',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      await _load(silent: true);
      _scrollToBottom();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _annulerAudio() {
    _previewPlayer.stop();
    setState(() { _audioState = _AudioState.idle; _recordPath = null; _recordSeconds = 0; });
  }

  // ── Supprimer message ──
  Future<void> _supprimerMessage(String messageId) async {
    try {
      await DioClient.instance.delete('/messages/$messageId');
      await _load(silent: true);
    } catch (_) {}
  }

  String _formatDuree(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: kNavBar,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new, color: kWhite, size: 20),
        ),
        actions: _conversation == null ? null : [
          // Voir l'annonce
          IconButton(
            onPressed: () => context.push('/annonces/${_conversation!.annonceId}'),
            icon: const Icon(Icons.real_estate_agent_outlined, color: kGold, size: 22),
            tooltip: 'Voir l\'annonce',
          ),
          // Voir le profil
          IconButton(
            onPressed: () {
              final myId = context.read<AuthProvider>().user?.id;
              final autreId = _conversation!.userId1 == myId
                  ? _conversation!.userId2
                  : _conversation!.userId1;
              context.push('/profil/public/$autreId');
            },
            icon: const Icon(Icons.person_outline, color: kWhite, size: 22),
            tooltip: 'Voir le profil',
          ),
          const SizedBox(width: 4),
        ],
        titleSpacing: 0,
        title: _conversation == null ? const SizedBox() : Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  _initiales(_conversation!.autreUserNom ?? '?'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kBlack),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conversation!.autreUserNom ?? '',
                    style: const TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_conversation!.annoncetitre != null)
                    Text(
                      _conversation!.annoncetitre!,
                      style: const TextStyle(color: kGold, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : Column(
              children: [
                // ── Messages ──
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline, size: 48, color: kGreyBorder),
                              const SizedBox(height: 12),
                              Text('Démarrez la conversation', style: AppText.bodySmall),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final msg = _messages[_messages.length - 1 - i];
                            // final msg = _messages[i];
                            final isMe = msg.senderId == myId;
                            final showDate = i == 0 ||
                                _messages[i].date?.substring(0, 10) !=
                                _messages[i - 1].date?.substring(0, 10);

                            return Column(
                              children: [
                                if (showDate && msg.date != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      children: [
                                        const Expanded(child: Divider()),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            AppFormatters.dateLocale(msg.date),
                                            style: AppText.cardMeta.copyWith(fontSize: 11),
                                          ),
                                        ),
                                        const Expanded(child: Divider()),
                                      ],
                                    ),
                                  ),
                                GestureDetector(
                                  onLongPress: isMe ? () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Supprimer ce message ?'),
                                        content: const Text('Cette action est irréversible.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: kRed))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) _supprimerMessage(msg.id);
                                  } : null,
                                  child: _MessageBubble(
                                    message: msg,
                                    isMe: isMe,
                                    baseUrl: ApiConstants.baseUrl.replaceAll('/api/v1', ''),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),

                // ── Miniatures médias en attente ──
                if (_mediasEnAttente.isNotEmpty)
                  Container(
                    color: kWhite,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    height: 100,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _mediasEnAttente.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final media = _mediasEnAttente[i];
                              final isVideo = media.name.toLowerCase().endsWith('.mp4') ||
                                  media.name.toLowerCase().endsWith('.mov') ||
                                  media.name.toLowerCase().endsWith('.webm');
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: isVideo
                                        ? Container(
                                            width: 80, height: 80,
                                            color: kDark,
                                            child: const Center(child: Icon(Icons.play_circle_fill, color: kWhite, size: 32)),
                                          )
                                        : Image.file(File(media.path), width: 80, height: 80, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 2, right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _mediasEnAttente.removeAt(i)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: kWhite, size: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _sending ? null : _envoyerMedias,
                          child: Container(
                            width: 42, height: 42,
                            decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                            child: _sending
                                ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: kBlack))
                                : const Icon(Icons.send, color: kBlack, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Zone enregistrement en cours ──
                Column(
                children: [
                if (_audioState == _AudioState.recording)...[
                  // const SizedBox(height: 20),
                  Container(
                    color: kWhite,
                    padding: EdgeInsets.fromLTRB(12, 20, 16, MediaQuery.of(context).padding.bottom + 20),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Text(_formatDuree(_recordSeconds), style: const TextStyle(color: kRed, fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(width: 12),
                        Expanded(child: Text('En cours...', style: AppText.bodySmall.copyWith(color: kGrey))),
                        const SizedBox(width: 12),
                        // Annuler
                        GestureDetector(
                          onTap: () => _stopRecording(cancel: true),
                          child: Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: kRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.delete_outline, color: kRed, size: 22),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Arrêter et prévisualiser
                        GestureDetector(
                          onTap: () => _stopRecording(),
                          child: Container(
                            width: 42, height: 42,
                            decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                            child: const Icon(Icons.stop, color: kBlack, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 40),
                ],
                ]),

                // ── Zone prévisualisation audio ──
              Column(
                children: [
                if (_audioState == _AudioState.preview)...[
                  // const SizedBox(height: 20),
                  Container(
                    color: kWhite,
                    padding: EdgeInsets.fromLTRB(12, 20, 16, 40),
                    child: Row(
                      children: [
                        // Supprimer
                        GestureDetector(
                          onTap: _annulerAudio,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: kRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.delete_outline, color: kRed, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Lecteur
                        GestureDetector(
                          onTap: () async {
                            if (_previewPlaying) {
                              await _previewPlayer.pause();
                            } else {
                              await _previewPlayer.play();
                            }
                          },
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: kGold.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Icon(_previewPlaying ? Icons.pause : Icons.play_arrow, color: kGold, size: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Barre de progression
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _previewTotal.inSeconds > 0
                                      ? (_previewPosition.inSeconds / _previewTotal.inSeconds).clamp(0.0, 1.0)
                                      : 0.0,
                                  backgroundColor: kGold.withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation(kGold),
                                  minHeight: 3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _previewPlaying ? _fmt(_previewPosition) : _fmt(_previewTotal),
                                style: const TextStyle(fontSize: 10, color: kGrey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Envoyer
                        GestureDetector(
                          onTap: _envoyerAudio,
                          child: Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                            child: const Icon(Icons.send, color: kBlack, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 0),
                 ], 
                ],
              ),

                // ── Zone saisie ──
                Column(
                children: [
                if (_audioState == _AudioState.idle)...[                  
                  // const SizedBox(height: 50),
                  Container(
                    color: kWhite,
                    padding: const EdgeInsets.fromLTRB(12, 15, 12, 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Bouton média
                        GestureDetector(
                          onTap: _ouvrirSelecteurMedia,
                          child: Container(
                            width: 38, height: 38,
                            decoration: const BoxDecoration(color: kGreyLight, shape: BoxShape.circle),
                            child: const Icon(Icons.image_outlined, color: kGrey, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Champ texte
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            decoration: BoxDecoration(
                              color: kGreyLight,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _msgCtrl,
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Écrire un message...',
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _envoyer(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bouton envoi / micro
                        _sending
                            ? Container(
                                width: 42, height: 42,
                                decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: kBlack),
                                ),
                              )
                            : ValueListenableBuilder(
                              valueListenable: _msgCtrl,
                              builder: (_, val, __) {
                                final hasText = val.text.trim().isNotEmpty;

                                if (_mediasEnAttente.isEmpty) {
                                  return GestureDetector(
                                    onTap: hasText ? _envoyer : _startRecording,
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: const BoxDecoration(
                                        color: kGold,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        hasText ? Icons.send : Icons.mic,
                                        color: kBlack,
                                        size: 20,
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox(width: 0);
                                }
                              },
                            )
                      ],
                    ),
                  ),
                  // const SizedBox(height: 20),
                ],
              ]),
              ],
            ),
    );
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return nom.isNotEmpty ? nom[0].toUpperCase() : '?';
  }
}

// ─── Bulle de message ─────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String baseUrl;

  const _MessageBubble({required this.message, required this.isMe, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isMe ? kGold : kWhite,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildContent(context),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(_heure(message.date), style: const TextStyle(fontSize: 10, color: kGrey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.isTexte) return _buildTexte();
    if (message.isAudio) return _buildAudio();
    if (message.isImage) return _buildImage(context);
    if (message.isVideo) return _buildVideo(context);
    return _buildTexte();
  }

  Widget _buildTexte() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(message.texte, style: const TextStyle(fontSize: 14, color: kBlack, height: 1.4)),
    );
  }

  Widget _buildAudio() {
    return _AudioBubble(
      url: '$baseUrl${message.fichierUrl}',
      isMe: isMe,
      duree: message.dureeAudio ?? 0,
    );
  }

  Widget _buildImage(BuildContext context) {
    final url = '$baseUrl${message.fichierUrl}';
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft:     const Radius.circular(18),
        topRight:    const Radius.circular(18),
        bottomLeft:  Radius.circular(isMe ? 18 : 4),
        bottomRight: Radius.circular(isMe ? 4 : 18),
      ),
      child: GestureDetector(
        onTap: () => _ouvrirImage(context, url),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 220, height: 180, fit: BoxFit.cover,
          placeholder: (_, __) => Container(width: 220, height: 180, color: kGreyLight,
              child: const Center(child: CircularProgressIndicator(color: kGold, strokeWidth: 2))),
          errorWidget: (_, __, ___) => Container(width: 220, height: 180, color: kGreyLight,
              child: const Icon(Icons.broken_image_outlined, color: kGrey)),
        ),
      ),
    );
  }

  Widget _buildVideo(BuildContext context) {
    final url = '$baseUrl${message.fichierUrl}';
    return _VideoBubble(url: url, isMe: isMe);
  }

  void _ouvrirImage(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: kWhite),
          ),
        ),
        body: Center(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain))),
      ),
    ));
  }

  String _heure(String? date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }
}

// ─── Bulle vidéo ─────────────────────────────────────────────────
class _VideoBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  const _VideoBubble({required this.url, required this.isMe});

  @override
  State<_VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<_VideoBubble> {
  VideoPlayerController? _vpCtrl;
  ChewieController? _chewieCtrl;
  bool _error = false;
  bool _initialized = false;

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _vpCtrl?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _vpCtrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _vpCtrl!.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _vpCtrl!,
        autoPlay: false,
        looping: false,
        aspectRatio: _vpCtrl!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: kGold,
          handleColor: kGold,
          bufferedColor: kGold.withValues(alpha: 0.3),
          backgroundColor: Colors.white24,
        ),
      );
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft:     const Radius.circular(18),
        topRight:    const Radius.circular(18),
        bottomLeft:  Radius.circular(widget.isMe ? 18 : 4),
        bottomRight: Radius.circular(widget.isMe ? 4 : 18),
      ),
      child: SizedBox(
        width: 220, height: 160,
        child: _error
            ? Container(color: kDark, child: const Center(child: Icon(Icons.error_outline, color: kGrey)))
            : !_initialized
                ? GestureDetector(
                    onTap: _init,
                    child: Container(
                      color: kDark,
                      child: const Center(child: Icon(Icons.play_circle_fill, color: kWhite, size: 48)),
                    ),
                  )
                : Chewie(controller: _chewieCtrl!),
      ),
    );
  }
}

// ─── Bulle audio ─────────────────────────────────────────────────
ja.AudioPlayer? _currentAudioPlayer;
_AudioBubbleState? _currentAudioBubble;
class _AudioBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  final int duree;
  const _AudioBubble({required this.url, required this.isMe, required this.duree});

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  late ja.AudioPlayer _player;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();
    _player.setLoopMode(ja.LoopMode.off);
    _total = Duration(seconds: widget.duree);
    _player.positionStream.listen((p) { if (mounted) setState(() => _position = p); });
    _player.durationStream.listen((d) { if (mounted) setState(() => _total = d ?? Duration(seconds: widget.duree)); });
    _player.playerStateStream.listen((s) async {
      if (mounted) setState(() => _playing = s.playing);


    if (s.processingState == ja.ProcessingState.completed) {
      await _player.pause();
      await _player.seek(Duration.zero);
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playing = false;
        });
      }
    }
    });
  }

  void _stopFromOutside() {
    _player.pause();

    if (mounted) {
      setState(() {
        _playing = false;
      });
    }
  }

  @override
  void dispose() {
    if (_currentAudioBubble == this) {
      _currentAudioBubble = null;
      _currentAudioPlayer = null;
    }

    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }

    if (_currentAudioBubble != null && _currentAudioBubble != this) {
      _currentAudioBubble!._stopFromOutside();
    }

    _currentAudioBubble = this;
    _currentAudioPlayer = _player;

    // Charger uniquement la première fois
    if (_player.audioSource == null ||
        _player.processingState == ja.ProcessingState.completed ||
        _player.processingState == ja.ProcessingState.idle) {
      await _player.setUrl(widget.url);
      await _player.setLoopMode(ja.LoopMode.off);
    }

    // reprend exactement là où il était en pause
    await _player.play();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final progress = _total.inSeconds > 0 ? _position.inSeconds / _total.inSeconds : 0.0;
    final color = widget.isMe ? kBlack : kGold;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: widget.isMe ? kBlack.withValues(alpha: 0.15) : kGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_playing ? Icons.pause : Icons.play_arrow, color: color, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(_playing ? _fmt(_position) : _fmt(_total), style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.mic, size: 14, color: color.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

// ─── StartConversationScreen ──────────────────────────────────────
class StartConversationScreen extends StatefulWidget {
  final String annonceId;
  const StartConversationScreen({super.key, required this.annonceId});

  @override
  State<StartConversationScreen> createState() => _StartConversationScreenState();
}

class _StartConversationScreenState extends State<StartConversationScreen> {
  final _msgCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _demarrer() async {
    final texte = _msgCtrl.text.trim();
    if (texte.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await DioClient.instance.post(
        '/messages/annonce/${widget.annonceId}',
        data: {'texte': texte},
      );
      final convId = res.data['id'] as String;
      if (mounted) context.replace('/messages/$convId');
    } catch (_) {
      setState(() { _error = 'Impossible de démarrer la conversation.'; _loading = false; });
    }
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
        title: const Text('Envoyer un message',
            style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Votre premier message',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kBlack)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGreyBorder),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: 5,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Bonjour, je suis intéressé par votre annonce...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: kRed, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _demarrer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: kBlack,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kBlack))
                    : const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}