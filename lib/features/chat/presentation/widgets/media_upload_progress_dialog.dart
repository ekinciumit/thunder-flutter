import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../l10n/app_localizations.dart';

/// Medya yükleme işlemi için progress dialog widget'ı
/// Sıkıştırma ve yükleme işlemlerini görsel olarak gösterir
/// Clean Architecture: Upload işlemi callback olarak dışarıdan verilir
class MediaUploadProgressDialog extends StatefulWidget {
  final File file;
  final bool isVideo;
  final Function(String downloadUrl) onComplete;
  final VoidCallback? onCancel;
  final int? maxWidth;
  final int? maxHeight;
  final int? quality;
  /// Upload işlemini yapan callback fonksiyon
  /// File ve progress callback alır, download URL döndürür
  final Future<String> Function(File file, void Function(double progress) onProgress) uploadFunction;

  const MediaUploadProgressDialog({
    super.key,
    required this.file,
    required this.isVideo,
    required this.uploadFunction,
    required this.onComplete,
    this.onCancel,
    this.maxWidth = 1920,
    this.maxHeight = 1080,
    this.quality = 85,
  });

  @override
  State<MediaUploadProgressDialog> createState() => _MediaUploadProgressDialogState();
}

class _MediaUploadProgressDialogState extends State<MediaUploadProgressDialog>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _status = '';
  bool _isCompressing = true;
  bool _isCancelled = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _startUpload();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startUpload() async {
    final l10n = AppLocalizations.of(context);
    
    try {
      File fileToUpload = widget.file;
      
      if (!widget.isVideo) {
        // Resim sıkıştırma
        setState(() {
          _status = l10n?.compressingImage ?? 'Resim sıkıştırılıyor...';
          _isCompressing = true;
        });
        
        // Sıkıştırılmış resmi geçici dosya olarak kaydet
        final compressedBytes = await _compressImage(widget.file);
        // Geçici dosya oluştur
        final tempFile = await _saveTempFile(compressedBytes, '.jpg');
        fileToUpload = tempFile;
      } else {
        // Video hazırlama
        setState(() {
          _status = l10n?.preparingVideo ?? 'Video hazırlanıyor...';
          _isCompressing = true;
        });
      }

      if (_isCancelled) return;

      setState(() {
        _status = l10n?.uploading ?? 'Yükleniyor...';
        _isCompressing = false;
        _progress = 0.0;
      });

      // Clean Architecture: Upload işlemi callback olarak dışarıdan verilir
      final downloadUrl = await widget.uploadFunction(
        fileToUpload,
        (progress) {
          if (!mounted || _isCancelled) return;
          setState(() {
            _progress = progress;
            _status = '${l10n?.uploading ?? 'Yükleniyor...'} ${(progress * 100).toStringAsFixed(0)}%';
          });
        },
      );

      if (!mounted || _isCancelled) return;

      Navigator.of(context).pop();
      widget.onComplete(downloadUrl);
      
    } catch (e) {
      if (!mounted || _isCancelled) return;
      
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n?.uploadError ?? 'Yükleme hatası'}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<File> _saveTempFile(Uint8List bytes, String extension) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/thunder_upload_${DateTime.now().millisecondsSinceEpoch}$extension');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  Future<Uint8List> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    
    // Görüntüyü decode et ve boyutlandır
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: widget.maxWidth,
      targetHeight: widget.maxHeight,
    );
    
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      return bytes; // Sıkıştırma başarısız olursa orijinali kullan
    }
    
    return byteData.buffer.asUint8List();
  }

  void _cancelUpload() {
    _isCancelled = true;
    Navigator.of(context).pop();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isCompressing
                        ? [AppColorConfig.secondaryColor, AppColorConfig.primaryColor]
                        : [AppColorConfig.primaryColor, AppColorConfig.tertiaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  _isCompressing
                      ? (widget.isVideo ? Icons.video_settings : Icons.photo_size_select_large)
                      : Icons.cloud_upload_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            
            // Title
            Text(
              widget.isVideo ? l10n.videoUpload : l10n.photoUpload,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            
            // Status Text
            Text(
              _status,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            
            // Progress Indicator
            if (!_isCompressing) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColorConfig.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              
              // Progress Percentage
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColorConfig.primaryColor,
                ),
              ),
            ] else ...[
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
            
            const SizedBox(height: AppTheme.spacingLg),
            
            // Cancel Button
            TextButton.icon(
              onPressed: _cancelUpload,
              icon: const Icon(Icons.close),
              label: Text(l10n.cancel),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Medya yükleme dialog'unu göster
/// Clean Architecture: Upload işlemi callback olarak verilir
Future<void> showMediaUploadProgress({
  required BuildContext context,
  required File file,
  required bool isVideo,
  required Future<String> Function(File file, void Function(double progress) onProgress) uploadFunction,
  required Function(String downloadUrl) onComplete,
  VoidCallback? onCancel,
  int? maxWidth,
  int? maxHeight,
  int? quality,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => MediaUploadProgressDialog(
      file: file,
      isVideo: isVideo,
      uploadFunction: uploadFunction,
      onComplete: onComplete,
      onCancel: onCancel,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    ),
  );
}

