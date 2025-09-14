import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String filePath, Duration duration) onRecordingComplete;
  final VoidCallback onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
  }

  Future<void> _startRecording() async {
    try {
      final success = await _audioService.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });
        
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        
        // Kayıt süresini takip et
        _startDurationTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ses kaydı başlatılamadı')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _startDurationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
        _startDurationTimer();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      final filePath = await _audioService.stopRecording();
      if (filePath != null) {
        _pulseController.stop();
        _waveController.stop();
        
        setState(() {
          _isRecording = false;
        });
        
        widget.onRecordingComplete(filePath, _recordingDuration);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt durdurma hatası: $e')),
      );
    }
  }

  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    _pulseController.stop();
    _waveController.stop();
    
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
    
    widget.onCancel();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Text(
            _isRecording ? 'Ses kaydı yapılıyor...' : 'Ses kaydına hazır',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recording visualization
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Waveform animation
                if (_isRecording)
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(double.infinity, 40),
                          painter: RecordingWaveformPainter(
                            animationValue: _waveAnimation.value,
                          ),
                        );
                      },
                    ),
                  ),
                
                // Duration
                if (_isRecording) ...[
                  const SizedBox(width: 16),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                
                // Record button
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording ? _pulseAnimation.value : 1.0,
                      child: GestureDetector(
                        onTap: _isRecording ? _stopRecording : _startRecording,
                        onLongPressStart: _isRecording ? null : (_) => _startRecording(),
                        onLongPressEnd: _isRecording ? null : (_) => _stopRecording(),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.red : Colors.deepPurple,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording ? Colors.red : Colors.deepPurple)
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Cancel button
                if (_isRecording) ...[
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _cancelRecording,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Instructions
          if (!_isRecording)
            const Text(
              'Mikrofon butonuna basılı tutun',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}

class RecordingWaveformPainter extends CustomPainter {
  final double animationValue;

  RecordingWaveformPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barWidth = 3.0;
    final spacing = 2.0;
    final totalBars = (size.width / (barWidth + spacing)).floor();
    
    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + spacing);
      final normalizedIndex = i / totalBars;
      final waveOffset = (animationValue + normalizedIndex) % 1.0;
      final barHeight = 4 + (waveOffset * 20);
      
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



