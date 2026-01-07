import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../../core/widgets/modern_components.dart';
import '../../core/theme/app_color_config.dart';
import '../../l10n/app_localizations.dart';

/// Modern chat mesaj giriş barı widget'ı
/// 
/// Voice recording, text input, emoji picker ve file attachments içerir
class ChatInputBar extends StatefulWidget {
  final TextEditingController textController;
  final bool showEmojiPicker;
  final bool isRecordingVoice;
  final bool isCancellingBySwipe;
  final Duration voiceRecordingDuration;
  final double voiceRecordingSwipeOffset;
  final VoidCallback onEmojiPickerToggle;
  final VoidCallback onSendTextMessage;
  final VoidCallback onVoiceRecordingCancel;
  final VoidCallback onVoiceRecordingStopAndSend;
  final VoidCallback onVoiceRecordingStart;
  final void Function(double offset, bool isCancelling) onVoiceRecordingSwipeUpdate;
  final void Function(ImageSource source, {bool isVideo}) onPickMedia;
  final VoidCallback onShowFilePicker;
  final Function(bool show) onEmojiPickerChanged;
  final Function(Emoji emoji) onEmojiSelected;

  const ChatInputBar({
    super.key,
    required this.textController,
    required this.showEmojiPicker,
    required this.isRecordingVoice,
    required this.isCancellingBySwipe,
    required this.voiceRecordingDuration,
    required this.voiceRecordingSwipeOffset,
    required this.onEmojiPickerToggle,
    required this.onSendTextMessage,
    required this.onVoiceRecordingCancel,
    required this.onVoiceRecordingStopAndSend,
    required this.onVoiceRecordingStart,
    required this.onVoiceRecordingSwipeUpdate,
    required this.onPickMedia,
    required this.onShowFilePicker,
    required this.onEmojiPickerChanged,
    required this.onEmojiSelected,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  static const double _swipeCancelThreshold = -80.0;

  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: widget.isRecordingVoice 
          ? _buildVoiceRecordingOverlay(isDark, theme)
          : _buildNormalInputBar(isDark, theme),
    );
  }

  Widget _buildVoiceRecordingOverlay(bool isDark, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final isCancelling = widget.isCancellingBySwipe;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCancelling
              ? [Colors.grey.withValues(alpha: 0.3), Colors.grey.withValues(alpha: 0.2)]
              : [Colors.red.withValues(alpha: 0.2), Colors.red.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isCancelling 
              ? Colors.grey.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              widget.onVoiceRecordingCancel();
              ModernSnackbar.showInfo(context, l10n?.voiceRecordingCancelled ?? 'Ses kaydı iptal edildi');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCancelling 
                    ? Colors.red.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_rounded,
                color: isCancelling ? Colors.white : Colors.white70,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _PulsingDot(isActive: !isCancelling),
          const SizedBox(width: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: isCancelling ? Colors.grey[400] : Colors.red[300],
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            child: Text(_formatRecordingDuration(widget.voiceRecordingDuration)),
          ),
          const Spacer(),
          const SizedBox(width: 6),
          Transform.translate(
            offset: Offset(widget.voiceRecordingSwipeOffset, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCancelling 
                      ? [Colors.grey, Colors.grey.shade600]
                      : [Colors.red, Colors.redAccent],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isCancelling
                        ? Colors.grey.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isCancelling ? Icons.delete : Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalInputBar(bool isDark, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(
            widget.showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
          onPressed: widget.onEmojiPickerToggle,
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.attach_file_rounded,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) {
            switch (value) {
              case 'photo':
                widget.onPickMedia(ImageSource.gallery, isVideo: false);
                break;
              case 'video':
                widget.onPickMedia(ImageSource.gallery, isVideo: true);
                break;
              case 'camera':
                widget.onPickMedia(ImageSource.camera, isVideo: false);
                break;
              case 'file':
                widget.onShowFilePicker();
                break;
            }
          },
          itemBuilder: (context) => [
            _buildPopupMenuItem('photo', Icons.photo_rounded, 'Fotoğraf', Colors.blue, isDark),
            _buildPopupMenuItem('video', Icons.videocam_rounded, 'Video', Colors.red, isDark),
            _buildPopupMenuItem('camera', Icons.camera_alt_rounded, 'Kamera', Colors.green, isDark),
            _buildPopupMenuItem('file', Icons.insert_drive_file_rounded, 'Dosya', Colors.orange, isDark),
          ],
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: widget.textController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.typeMessage ?? 'Mesaj yaz...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[500],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              minLines: 1,
              maxLines: 4,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
              cursorColor: AppColorConfig.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.textController,
          builder: (context, value, child) {
            final hasText = value.text.trim().isNotEmpty;
            
            if (hasText) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onSendTextMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColorConfig.primaryColor,
                            AppColorConfig.primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColorConfig.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: _VoiceRecordingButton(
                  onVoiceRecordingStart: widget.onVoiceRecordingStart,
                  onVoiceRecordingStopAndSend: widget.onVoiceRecordingStopAndSend,
                  onVoiceRecordingCancel: widget.onVoiceRecordingCancel,
                  onVoiceRecordingSwipeUpdate: widget.onVoiceRecordingSwipeUpdate,
                  isCancellingBySwipe: widget.isCancellingBySwipe,
                  swipeCancelThreshold: _swipeCancelThreshold,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value, 
    IconData icon, 
    String text, 
    Color color,
    bool isDark,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Voice recording button with manual pointer tracking (AVD uyumlu)
class _VoiceRecordingButton extends StatefulWidget {
  final VoidCallback onVoiceRecordingStart;
  final VoidCallback onVoiceRecordingStopAndSend;
  final VoidCallback onVoiceRecordingCancel;
  final void Function(double offset, bool isCancelling) onVoiceRecordingSwipeUpdate;
  final bool isCancellingBySwipe;
  final double swipeCancelThreshold;

  const _VoiceRecordingButton({
    required this.onVoiceRecordingStart,
    required this.onVoiceRecordingStopAndSend,
    required this.onVoiceRecordingCancel,
    required this.onVoiceRecordingSwipeUpdate,
    required this.isCancellingBySwipe,
    required this.swipeCancelThreshold,
  });

  @override
  State<_VoiceRecordingButton> createState() => _VoiceRecordingButtonState();
}

class _VoiceRecordingButtonState extends State<_VoiceRecordingButton> {
  DateTime? _pressStartTime;
  Offset? _pressStartPosition;
  Timer? _longPressTimer;
  bool _isLongPressing = false;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (kDebugMode) {
      debugPrint('👆 [VOICE_BUTTON] PointerDown: ${event.position}');
    }
    _pressStartTime = DateTime.now();
    _pressStartPosition = event.position;
    
    // Long press timer başlat (500ms sonra)
    _longPressTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _pressStartTime != null) {
        _isLongPressing = true;
        if (kDebugMode) {
          debugPrint('🎬 [VOICE_BUTTON] Long press başladı (500ms geçti)');
        }
        widget.onVoiceRecordingStart();
      }
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_pressStartPosition == null || !_isLongPressing) return;
    
    final offset = (event.position.dx - _pressStartPosition!.dx).clamp(-150.0, 0.0);
    final isCancelling = offset < widget.swipeCancelThreshold;
    widget.onVoiceRecordingSwipeUpdate(offset, isCancelling);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (kDebugMode) {
      debugPrint('👆 [VOICE_BUTTON] PointerUp çağrıldı');
      debugPrint('👆 [VOICE_BUTTON] isLongPressing: $_isLongPressing');
      debugPrint('👆 [VOICE_BUTTON] isCancellingBySwipe: ${widget.isCancellingBySwipe}');
    }
    
    _longPressTimer?.cancel();
    _longPressTimer = null;
    
    if (_isLongPressing) {
      // Long press başlamıştı, şimdi durdur ve gönder
      _isLongPressing = false;
      
      if (widget.isCancellingBySwipe) {
        if (kDebugMode) {
          debugPrint('❌ [VOICE_BUTTON] İptal ediliyor (sola kaydırıldı)');
        }
        widget.onVoiceRecordingCancel();
        if (mounted) {
          ModernSnackbar.showInfo(context, AppLocalizations.of(context)?.voiceRecordingCancelled ?? 'Ses kaydı iptal edildi');
        }
      } else {
        if (kDebugMode) {
          debugPrint('✅ [VOICE_BUTTON] Gönderme başlatılıyor...');
        }
        widget.onVoiceRecordingStopAndSend();
      }
    } else {
      // Long press başlamamış, sadece normal tap
      if (kDebugMode) {
        debugPrint('ℹ️ [VOICE_BUTTON] Normal tap, long press başlamamış');
      }
    }
    
    _pressStartTime = null;
    _pressStartPosition = null;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (kDebugMode) {
      debugPrint('🚫 [VOICE_BUTTON] PointerCancel çağrıldı');
    }
    _longPressTimer?.cancel();
    _longPressTimer = null;
    
    if (_isLongPressing) {
      _isLongPressing = false;
      widget.onVoiceRecordingCancel();
    }
    
    _pressStartTime = null;
    _pressStartPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: GestureDetector(
        // GestureDetector'ı da tutuyoruz (fallback için)
        onLongPressStart: (details) {
          if (kDebugMode) {
            debugPrint('🎬 [VOICE] GestureDetector onLongPressStart (fallback)');
          }
          // Listener zaten handle ediyor, ama yine de çağıralım
          if (!_isLongPressing) {
            _isLongPressing = true;
            widget.onVoiceRecordingStart();
          }
        },
        onLongPressMoveUpdate: (details) {
          final offset = details.offsetFromOrigin.dx.clamp(-150.0, 0.0);
          final isCancelling = offset < widget.swipeCancelThreshold;
          widget.onVoiceRecordingSwipeUpdate(offset, isCancelling);
        },
        onLongPressEnd: (_) {
          if (kDebugMode) {
            debugPrint('🎤 [VOICE] GestureDetector onLongPressEnd (fallback)');
          }
          if (_isLongPressing) {
            _isLongPressing = false;
            if (widget.isCancellingBySwipe) {
              widget.onVoiceRecordingCancel();
            } else {
              widget.onVoiceRecordingStopAndSend();
            }
          }
        },
        onLongPressCancel: () {
          if (kDebugMode) {
            debugPrint('🚫 [VOICE] GestureDetector onLongPressCancel (fallback)');
          }
          if (_isLongPressing) {
            _isLongPressing = false;
            widget.onVoiceRecordingCancel();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mic_rounded,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[700],
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Pulsing dot animation for voice recording
class _PulsingDot extends StatefulWidget {
  final bool isActive;

  const _PulsingDot({required this.isActive});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      );
    }
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow effect
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5 * _opacityAnimation.value),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Inner dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}

