import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import 'modern_loading_widget.dart';

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
  
  bool _isPlaying = false;
  final Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      if (widget.duration != null) {
        _totalDuration = widget.duration!;
        _isLoading = false;
        setState(() {});
        return;
      }

      // Ses dosyası süresini al
      final duration = await _audioService.getAudioDuration(
        widget.localPath ?? widget.audioUrl,
      );
      
      if (duration != null) {
        _totalDuration = duration;
      }
      
      _isLoading = false;
      setState(() {});
    } catch (e) {
      _isLoading = false;
      setState(() {});
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioService.stopAudio();
        _animationController.stop();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioService.playAudio(widget.localPath ?? widget.audioUrl);
        _animationController.repeat();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ses oynatma hatası: $e')),
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
              ? Colors.deepPurple[500] 
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
                          : Colors.deepPurple.withValues(alpha: 0.1),
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
                            color: widget.isMe ? Colors.white : Colors.deepPurple,
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
                          animation: _animation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(double.infinity, 20),
                              painter: WaveformPainter(
                                isPlaying: _isPlaying,
                                progress: _currentPosition.inMilliseconds / 
                                    _totalDuration.inMilliseconds,
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
            
            const SizedBox(height: 8),
            
            // Progress bar
            if (!_isLoading && _totalDuration > Duration.zero)
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: widget.isMe 
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(1),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _currentPosition.inMilliseconds / 
                      _totalDuration.inMilliseconds,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isMe ? Colors.white : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
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
      ..color = isMe ? Colors.white : Colors.deepPurple
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barWidth = 3.0;
    final spacing = 2.0;
    final totalBars = (size.width / (barWidth + spacing)).floor();
    
    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + spacing);
      final barHeight = isPlaying 
          ? 4 + (animationValue * 12 * (1 - (i / totalBars)))
          : 4 + (progress * 12 * (1 - (i / totalBars)));
      
      canvas.drawLine(
        Offset(x, size.height / 2 - barHeight / 2),
        Offset(x, size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}



