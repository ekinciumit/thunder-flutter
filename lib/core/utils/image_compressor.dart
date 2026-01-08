import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image compression utility
/// Resizes and compresses images before upload to reduce storage costs
/// 
/// **Maliyet Tasarrufu:** %70-80 storage maliyeti azalır
class ImageCompressor {
  /// Compress profile photo
  /// Target: 800x800px, 80% quality
  /// 
  /// **Kullanım:** Profil fotoğrafı upload öncesi
  static Future<File> compressProfilePhoto(File imageFile) async {
    return _compressImage(
      imageFile,
      maxWidth: 800,
      maxHeight: 800,
      quality: 80,
    );
  }

  /// Compress event cover photo
  /// Target: 1200x1200px, 85% quality
  /// 
  /// **Kullanım:** Event cover fotoğrafı upload öncesi
  static Future<File> compressEventCover(File imageFile) async {
    return _compressImage(
      imageFile,
      maxWidth: 1200,
      maxHeight: 1200,
      quality: 85,
    );
  }

  /// Compress chat media (image)
  /// Target: 1000x1000px, 85% quality
  /// 
  /// **Kullanım:** Chat medya (image) upload öncesi
  static Future<File> compressChatMedia(File imageFile) async {
    return _compressImage(
      imageFile,
      maxWidth: 1000,
      maxHeight: 1000,
      quality: 85,
    );
  }

  /// Internal compression method
  /// 
  /// Resizes image to max dimensions while maintaining aspect ratio,
  /// then compresses as JPEG with specified quality
  static Future<File> _compressImage(
    File imageFile, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    try {
      // Read image bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Decode image using image package
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate new dimensions while maintaining aspect ratio
      int newWidth = decodedImage.width;
      int newHeight = decodedImage.height;
      
      if (newWidth > maxWidth || newHeight > maxHeight) {
        final aspectRatio = newWidth / newHeight;
        
        if (newWidth > newHeight) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
          if (newHeight > maxHeight) {
            newHeight = maxHeight;
            newWidth = (maxHeight * aspectRatio).round();
          }
        } else {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
          if (newWidth > maxWidth) {
            newWidth = maxWidth;
            newHeight = (maxWidth / aspectRatio).round();
          }
        }
      }

      // Resize image
      final resizedImage = img.copyResize(
        decodedImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG with quality
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: quality),
      );

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final compressedPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Save compressed image
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);

      if (kDebugMode) {
        final originalSize = await imageFile.length();
        final compressedSize = await compressedFile.length();
        final reduction = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
        debugPrint('✅ [IMAGE_COMPRESSOR] Compressed: ${originalSize ~/ 1024}KB → ${compressedSize ~/ 1024}KB ($reduction% reduction)');
      }

      return compressedFile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [IMAGE_COMPRESSOR] Compression error: $e');
      }
      // If compression fails, return original file
      return imageFile;
    }
  }
}

