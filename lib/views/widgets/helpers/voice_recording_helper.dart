import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../services/audio_service.dart';
import '../../../core/widgets/modern_components.dart';

/// Helper class for managing voice recording state and operations
class VoiceRecordingHelper {
  final AudioService _audioService = AudioService();
  
  bool isRecording = false;
  Duration duration = Duration.zero;
  DateTime? startTime;
  Timer? timer;
  double swipeOffset = 0.0;
  bool isCancellingBySwipe = false;

  /// Start voice recording
  Future<void> startRecording({
    required VoidCallback onStateChanged,
    required BuildContext context,
  }) async {
    if (kDebugMode) {
      debugPrint('🎬 [VOICE_HELPER] startRecording çağrıldı');
    }
    try {
      if (kDebugMode) {
        debugPrint('🎬 [VOICE_HELPER] AudioService.startRecording() çağrılıyor...');
      }
      final success = await _audioService.startRecording();
      if (kDebugMode) {
        debugPrint('🎬 [VOICE_HELPER] startRecording sonucu: $success');
      }
      if (success) {
        isRecording = true;
        duration = Duration.zero;
        startTime = DateTime.now();
        
        if (kDebugMode) {
          debugPrint('✅ [VOICE_HELPER] Kayıt başlatıldı, timer başlatılıyor...');
        }
        
        // Start duration timer
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (isRecording && startTime != null) {
            duration = DateTime.now().difference(startTime!);
            onStateChanged();
          }
        });
        
        // Haptic feedback
        HapticFeedback.mediumImpact();
        onStateChanged();
        
        if (kDebugMode) {
          debugPrint('✅ [VOICE_HELPER] startRecording tamamlandı');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ [VOICE_HELPER] startRecording başarısız (success: false)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VOICE_HELPER] startRecording hatası: $e');
      }
      if (context.mounted) {
        ModernSnackbar.showError(context, 'Ses kaydı başlatılamadı: $e');
      }
    }
  }

  /// Stop and send voice recording
  Future<String?> stopRecording({
    required Function(String filePath, Duration duration) onSend,
    required BuildContext context,
    required VoidCallback onStateChanged,
  }) async {
    if (kDebugMode) {
      debugPrint('🛑 [VOICE_HELPER] stopRecording çağrıldı');
      debugPrint('🛑 [VOICE_HELPER] isRecording: $isRecording');
      debugPrint('🛑 [VOICE_HELPER] duration: ${duration.inMilliseconds}ms');
    }
    
    // isRecording kontrolünü kaldırdık - AudioService kayıt yapıyor olabilir ama state güncellenmemiş olabilir
    // Duration kontrolü yeterli (minimum 0.5 saniye)
    if (duration.inMilliseconds < 100) {
      // Çok kısa süre - kayıt başlamamış olabilir
      if (kDebugMode) {
        debugPrint('⚠️ [VOICE_HELPER] Çok kısa süre (${duration.inMilliseconds}ms < 100ms), kayıt başlamamış olabilir');
      }
      if (isRecording) {
        await _audioService.cancelRecording();
        isRecording = false;
        duration = Duration.zero;
        swipeOffset = 0.0;
        isCancellingBySwipe = false;
        onStateChanged();
      }
      return null;
    }
    
    timer?.cancel();
    
    // Minimum 0.5 second recording required (1 saniye çok uzun olabilir)
    if (duration.inMilliseconds < 500) {
      if (kDebugMode) {
        debugPrint('⚠️ [VOICE_HELPER] Çok kısa kayıt (${duration.inMilliseconds}ms < 500ms), iptal ediliyor');
      }
      await _audioService.cancelRecording();
      isRecording = false;
      duration = Duration.zero;
      swipeOffset = 0.0;
      isCancellingBySwipe = false;
      onStateChanged();
      if (context.mounted) {
        ModernSnackbar.showInfo(context, 'Çok kısa, daha uzun basılı tutun');
      }
      return null;
    }
    
    try {
      // Duration'ı kaydet (state güncellemesinden önce)
      final savedDuration = duration;
      
      if (kDebugMode) {
        debugPrint('📹 [VOICE_HELPER] AudioService.stopRecording() çağrılıyor...');
      }
      final filePath = await _audioService.stopRecording();
      
      if (kDebugMode) {
        debugPrint('📹 [VOICE_HELPER] stopRecording tamamlandı, filePath: $filePath');
      }
      
      // Önce state'i güncelle (kayıt durdu)
      isRecording = false;
      duration = Duration.zero;
      swipeOffset = 0.0;
      isCancellingBySwipe = false;
      onStateChanged(); // UI'ı hemen güncelle
      
      if (filePath != null && filePath.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ [VOICE_HELPER] Dosya yolu alındı: $filePath');
          debugPrint('✅ [VOICE_HELPER] Duration: ${savedDuration.inMilliseconds}ms');
          debugPrint('✅ [VOICE_HELPER] onSend callback çağrılıyor...');
        }
        // Haptic feedback
        HapticFeedback.lightImpact();
        
        // onSend'i çağır (async işlem - upload ve send)
        // savedDuration kullan (duration artık zero)
        await onSend(filePath, savedDuration);
        
        if (kDebugMode) {
          debugPrint('✅ [VOICE_HELPER] onSend callback tamamlandı');
        }
      } else {
        // Dosya yolu null veya boşsa hata göster
        if (kDebugMode) {
          debugPrint('❌ [VOICE_HELPER] Dosya yolu null veya boş!');
        }
        if (context.mounted) {
          ModernSnackbar.showError(context, 'Ses kaydı alınamadı');
        }
      }
      return filePath;
    } catch (e) {
      // Hata durumunda da state'i temizle
      isRecording = false;
      duration = Duration.zero;
      swipeOffset = 0.0;
      isCancellingBySwipe = false;
      onStateChanged();
      
      if (context.mounted) {
        ModernSnackbar.showError(context, 'Ses kaydı gönderilemedi: $e');
      }
      return null;
    }
  }

  /// Cancel voice recording
  Future<void> cancelRecording({
    required VoidCallback onStateChanged,
  }) async {
    timer?.cancel();
    await _audioService.cancelRecording();
    
    isRecording = false;
    duration = Duration.zero;
    swipeOffset = 0.0;
    isCancellingBySwipe = false;
    
    HapticFeedback.lightImpact();
    onStateChanged();
  }

  /// Update swipe offset
  void updateSwipeOffset(double offset, bool isCancelling, VoidCallback onStateChanged) {
    if (isRecording) {
      swipeOffset = offset;
      isCancellingBySwipe = isCancelling;
      onStateChanged();
    }
  }

  /// Reset swipe state
  void resetSwipeState(VoidCallback onStateChanged) {
    swipeOffset = 0.0;
    isCancellingBySwipe = false;
    onStateChanged();
  }

  /// Dispose resources
  void dispose() {
    timer?.cancel();
  }
}

