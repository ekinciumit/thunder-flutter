import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../services/audio_service.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../../core/widgets/modern_loading_widget.dart';

class VoiceMessageWidget extends StatefulWidget {
  final String audioUrl;
  final String? localPath;
  final Duration? duration;
  final bool isMe;
  final VoidCallback? onLongPress;

  const VoiceMessageWidget({
    super.key,
    required this.audioUrl,
    this.localPath,
    this.duration,
    required this.isMe,
    this.onLongPress,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  Duration _totalDuration = Duration.zero;
  bool _isLoading = true;
  
  // Get current playing state from AudioService
  bool get _isPlaying => _audioService.stateNotifier.isUrlPlaying(_audioUrl);
  Duration get _currentPosition => _audioService.stateNotifier.currentPosition;
  
  String get _audioUrl => widget.localPath ?? widget.audioUrl;

  @override
  void initState() {
    super.initState();
    // Daha hızlı animasyon (WhatsApp tarzı için)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Daha hızlı
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Listen to audio state changes
    _audioService.stateNotifier.addListener(_onAudioStateChanged);
    
    _initializeAudio();
  }
  
  void _onAudioStateChanged() {
    if (!mounted) return;
    
    setState(() {
      // State updated, rebuild widget
      if (_isPlaying) {
        // Oynatma sırasında sürekli animasyon
        if (!_animationController.isAnimating) {
          _animationController.repeat();
        }
      } else {
        // Durdurulduğunda animasyonu durdur
        _animationController.stop();
        _animationController.reset();
      }
    });
  }

  Future<void> _initializeAudio() async {
    try {
      if (widget.duration != null) {
        _totalDuration = widget.duration!;
        _isLoading = false;
        if (mounted) setState(() {});
        return;
      }

      // Ses dosyası süresini al
      final duration = await _audioService.getAudioDuration(_audioUrl);
      
      if (duration != null) {
        _totalDuration = duration;
      }
      
      _isLoading = false;
      if (mounted) setState(() {});
    } catch (e) {
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioService.stopAudio();
      } else {
        await _audioService.playAudio(_audioUrl);
      }
      // State will be updated via _onAudioStateChanged listener
    } catch (e) {
      if (!mounted) return;
      ModernSnackbar.showError(
        context,
        'Ses oynatma hatası: $e',
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioService.stateNotifier.removeListener(_onAudioStateChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isMe 
              ? AppColorConfig.primaryColor 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Play/Pause button
                GestureDetector(
                  onTap: _isLoading ? null : _togglePlayPause,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isMe 
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColorConfig.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: ModernLoadingWidget(size: 16, showMessage: false),
                            ),
                          )
                        : Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: widget.isMe ? Colors.white : AppColorConfig.primaryColor,
                            size: 20,
                          ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Waveform animation
                Expanded(
                  child: _isLoading
                      ? Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: widget.isMe 
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )
                      : AnimatedBuilder(
                          animation: Listenable.merge([
                            _animation,
                            _audioService.stateNotifier,
                          ]),
                          builder: (context, child) {
                            // Progress hesapla (division by zero önle)
                            final currentPos = _currentPosition;
                            final totalDur = _totalDuration;
                            final progress = totalDur.inMilliseconds > 0
                                ? (currentPos.inMilliseconds / totalDur.inMilliseconds).clamp(0.0, 1.0)
                                : 0.0;
                            
                            return CustomPaint(
                              size: const Size(double.infinity, 20),
                              painter: WaveformPainter(
                                isPlaying: _isPlaying,
                                progress: progress,
                                isMe: widget.isMe,
                                animationValue: _animation.value,
                              ),
                            );
                          },
                        ),
                ),
                
                const SizedBox(width: 8),
                
                // Duration
                Text(
                  _isLoading 
                      ? '--:--' 
                      : _formatDuration(_totalDuration),
                  style: TextStyle(
                    color: widget.isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class WaveformPainter extends CustomPainter {
  final bool isPlaying;
  final double progress;
  final bool isMe;
  final double animationValue;

  WaveformPainter({
    required this.isPlaying,
    required this.progress,
    required this.isMe,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isMe ? Colors.white : AppColorConfig.primaryColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final barWidth = 3.0;
    final spacing = 2.0;
    final totalBars = (size.width / (barWidth + spacing)).floor();
    final maxBarHeight = size.height * 0.9; // Maksimum çubuk yüksekliği
    final minBarHeight = 4.0; // Minimum çubuk yüksekliği
    
    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + spacing);
      
      double barHeight;
      
      if (isPlaying) {
        // Oynatma sırasında: Her çubuğa farklı animasyon hızı ver (WhatsApp tarzı)
        // Her çubuk için farklı bir "frekans" kullan (sinüs dalgası benzeri)
        final phase = (i * 0.4) + (animationValue * 2 * math.pi); // Her çubuk farklı faz
        final normalizedPosition = i / totalBars; // Çubuk pozisyonu (0-1)
        
        // Sinüs dalgası kullanarak animasyonlu yükseklik
        final waveValue = (math.sin(phase) + 1) / 2; // 0-1 arası
        
        // Progress'e göre çubukların görünürlüğü (soldan sağa)
        final progressFactor = normalizedPosition <= progress ? 1.0 : 0.4;
        
        // Her çubuk için farklı base yükseklik (rastgele görünüm için)
        // Çubukların yüksekliği rastgele dağıtılmış gibi görünsün
        final randomSeed = (i * 17) % 100 / 100.0; // Pseudo-random (i'ye göre)
        final baseHeight = minBarHeight + (maxBarHeight - minBarHeight) * 
            (0.2 + (randomSeed * 0.8)); // 0.2-1.0 arası base
        
        // Animasyonlu yükseklik = base + wave animasyonu
        barHeight = baseHeight * progressFactor * (0.4 + (waveValue * 0.6));
        
        // Minimum yükseklik garantisi
        barHeight = barHeight.clamp(minBarHeight, maxBarHeight);
      } else {
        // Oynatma durduğunda: Progress'e göre statik göster
        final normalizedPosition = i / totalBars;
        if (normalizedPosition <= progress && progress > 0) {
          // Oynatılan kısım: Daha yüksek
          final randomSeed = (i * 17) % 100 / 100.0;
          barHeight = minBarHeight + (maxBarHeight - minBarHeight) * 
              (0.3 + (randomSeed * 0.7));
        } else {
          // Oynatılmayan kısım: Daha düşük
          barHeight = minBarHeight * 0.7;
        }
        barHeight = barHeight.clamp(minBarHeight * 0.7, maxBarHeight);
      }
      
      canvas.drawLine(
        Offset(x, size.height / 2 - barHeight / 2),
        Offset(x, size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is WaveformPainter) {
      return oldDelegate.isPlaying != isPlaying ||
          oldDelegate.progress != progress ||
          oldDelegate.animationValue != animationValue;
    }
    return true;
  }
}



