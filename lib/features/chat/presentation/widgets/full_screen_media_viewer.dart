import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/widgets/modern_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../../views/widgets/modern_loading_widget.dart';

/// Tam ekran medya görüntüleyici
/// 
/// Özellikleri:
/// - Fotoğraf ve video desteği
/// - Pinch-to-zoom
/// - İndirme özelliği
/// - Kaydırarak kapatma
class FullScreenMediaViewer extends StatefulWidget {
  final String mediaUrl;
  final bool isVideo;
  final String? heroTag;
  final String? title;

  const FullScreenMediaViewer({
    super.key,
    required this.mediaUrl,
    this.isVideo = false,
    this.heroTag,
    this.title,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.addListener(() {
      if (_animation != null) {
        _transformationController.value = _animation!.value;
      }
    });

    if (widget.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
    await _videoController!.initialize();
    setState(() {
      _isVideoInitialized = true;
    });
    _videoController!.play();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _onDoubleTap(TapDownDetails details) {
    final position = details.localPosition;
    final endMatrix = _transformationController.value.isIdentity()
        ? (Matrix4.identity()
          ..translateByDouble(-position.dx * 2, -position.dy * 2, 0, 0)
          ..scaleByDouble(3.0, 3.0, 3.0, 1.0))
        : Matrix4.identity();

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0);
  }

  Future<void> _downloadMedia() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // Dart'ın built-in HttpClient kullan (dependency gerektirmez)
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(widget.mediaUrl));
      final response = await request.close();

      final contentLength = response.contentLength;
      final bytes = <int>[];
      int received = 0;

      await for (final chunk in response) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() {
            _downloadProgress = received / contentLength;
          });
        }
      }

      client.close();

      // Dosyayı kaydet
      final dir = await getApplicationDocumentsDirectory();
      final extension = widget.isVideo ? 'mp4' : 'jpg';
      final fileName = 'thunder_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ModernSnackbar.showSuccess(
          context,
          '${widget.isVideo ? 'Video' : 'Fotoğraf'} indirildi: $fileName',
        );
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(
          context,
          'İndirme hatası: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.title != null
            ? Text(
                widget.title!,
                style: const TextStyle(color: Colors.white),
              )
            : null,
        actions: [
          // İndirme butonu
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              tooltip: l10n?.save ?? 'Download',
              onPressed: _downloadMedia,
            ),
        ],
      ),
      body: GestureDetector(
        onDoubleTapDown: widget.isVideo ? null : _onDoubleTap,
        child: Center(
          child: widget.isVideo ? _buildVideoPlayer() : _buildImageViewer(),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: widget.mediaUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: ModernLoadingWidget(size: 48, showMessage: false),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.error, color: Colors.red, size: 48),
      ),
    );

    if (widget.heroTag != null) {
      imageWidget = Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      child: imageWidget,
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: ModernLoadingWidget(size: 48, message: 'Video yükleniyor...'),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          // Video kontrolleri
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black45,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Theme.of(context).colorScheme.primary,
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Play/Pause ve süre
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_formatDuration(_videoController!.value.position)} / ${_formatDuration(_videoController!.value.duration)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Tam ekran medya görüntüleyici açma helper fonksiyonu
void openFullScreenMedia(
  BuildContext context, {
  required String mediaUrl,
  bool isVideo = false,
  String? heroTag,
  String? title,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: FullScreenMediaViewer(
            mediaUrl: mediaUrl,
            isVideo: isVideo,
            heroTag: heroTag,
            title: title,
          ),
        );
      },
    ),
  );
}

