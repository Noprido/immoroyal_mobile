import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/theme/colors.dart';

/// Visionneuse principale : grande image + rangée de miniatures
class MediaViewer extends StatefulWidget {
  final List<Map<String, String>> medias;
  final String baseUrl;

  const MediaViewer({super.key, required this.medias, required this.baseUrl});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  int _current = 0;

  void _openGallery(int index) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _GalleryModal(
        medias: widget.medias,
        initialIndex: index,
        baseUrl: widget.baseUrl,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.medias.isEmpty) {
      return Container(
        height: 300,
        color: kGreyLight,
        child: const Center(child: Icon(Icons.image_outlined, size: 48, color: kGrey)),
      );
    }

    final current = widget.medias[_current];
    final isVideo = current['type'] == 'video';
    final displayUrl = '${widget.baseUrl}${current['url']}';

    return Column(
      children: [
        // ── Image principale ──
        GestureDetector(
          onTap: () => _openGallery(_current),
          child: Stack(
            children: [
              SizedBox(
                height: 300,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: displayUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: kGreyLight),
                  errorWidget: (_, __, ___) => Container(
                    color: kGreyLight,
                    child: const Icon(Icons.broken_image_outlined, color: kGrey, size: 48),
                  ),
                ),
              ),
              // Overlay play si vidéo
              if (isVideo)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(Icons.play_circle_fill, color: kWhite, size: 64),
                    ),
                  ),
                ),
              // Compteur
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_current + 1} / ${widget.medias.length}',
                    style: const TextStyle(color: kWhite, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Rangée miniatures ──
        if (widget.medias.length > 1)
          Container(
            color: kWhite,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.medias.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final media = widget.medias[i];
                  final isSelected = i == _current;
                  final thumbUrl = '${widget.baseUrl}${media['url']}';
                  final isVid = media['type'] == 'video';

                  return GestureDetector(
                    onTap: () => setState(() => _current = i),
                    child: Container(
                      width: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? kGold : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: thumbUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: kGreyLight),
                              errorWidget: (_, __, ___) => Container(color: kGreyLight),
                            ),
                            if (isVid)
                              Container(
                                color: Colors.black26,
                                child: const Center(
                                  child: Icon(Icons.play_arrow, color: kWhite, size: 20),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MODALE GALERIE PLEIN ÉCRAN
// ═══════════════════════════════════════════════════════════════════

class _GalleryModal extends StatefulWidget {
  final List<Map<String, String>> medias;
  final int initialIndex;
  final String baseUrl;

  const _GalleryModal({
    required this.medias,
    required this.initialIndex,
    required this.baseUrl,
  });

  @override
  State<_GalleryModal> createState() => _GalleryModalState();
}

class _GalleryModalState extends State<_GalleryModal> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current  = widget.initialIndex;
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
              final media   = widget.medias[i];
              final isVideo = media['type'] == 'video';
              // Pour la vidéo : utilise videoUrl si disponible, sinon url
              final videoUrl = media['videoUrl'] ?? media['url']!;
              final photoUrl = '${widget.baseUrl}${media['url']}';
              final fullVideoUrl = '${widget.baseUrl}$videoUrl';

              return isVideo
                  ? _VideoPlayer(url: fullVideoUrl)
                  : _PhotoViewer(url: photoUrl);
            },
          ),

          // Bouton fermer
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.close, color: kWhite, size: 22),
                  ),
                ),
              ),
            ),
          ),

          // Compteur
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${_current + 1} / ${widget.medias.length}',
                    style: const TextStyle(color: kWhite, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),

          // Indicateurs
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
                      width:  i == _current ? 20 : 6,
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

// ─── Lecteur vidéo ────────────────────────────────────────────────
class _VideoPlayer extends StatefulWidget {
  final String url;
  const _VideoPlayer({required this.url});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  VideoPlayerController? _vpCtrl;
  ChewieController?      _chewieCtrl;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

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
          bufferedColor: kGold.withOpacity(0.3),
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