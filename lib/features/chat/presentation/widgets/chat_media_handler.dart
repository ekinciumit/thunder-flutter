import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../viewmodels/chat_viewmodel.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/modern_components.dart';
import 'media_upload_progress_dialog.dart';

/// Chat media handler
/// 
/// Handles image/video picking and uploading for chat
class ChatMediaHandler {
  final BuildContext context;
  final ChatViewModel chatViewModel;
  final AuthViewModel authViewModel;
  final String chatId;
  final String currentUserId;
  final String currentUserName;
  final Function(String? imageUrl, String? videoUrl) onMediaUploaded;

  ChatMediaHandler({
    required this.context,
    required this.chatViewModel,
    required this.authViewModel,
    required this.chatId,
    required this.currentUserId,
    required this.currentUserName,
    required this.onMediaUploaded,
  });

  Future<void> pickMedia(ImageSource source, {bool isVideo = false}) async {
    if (!context.mounted || chatId.isEmpty) return;

    try {
      final picker = ImagePicker();
      final picked = isVideo
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      final file = File(picked.path);

      // Dosya kontrolü
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.fileNotFound ?? 'File not found',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Dosya boyutu kontrolü (max 50MB)
      final fileSize = await file.length();
      const maxFileSize = 50 * 1024 * 1024; // 50MB
      if (fileSize > maxFileSize) {
        if (context.mounted) {
          ModernSnackbar.showError(
            context,
            AppLocalizations.of(context)?.fileTooLarge ?? 
            'File too large (Max: 50MB)',
          );
        }
        return;
      }

      if (!context.mounted) return;

      // Clean Architecture: ChatViewModel üzerinden yükleme
      final ext = isVideo ? 'mp4' : 'jpg';
      final storagePath = 'chat_media/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final contentType = isVideo ? 'video/mp4' : 'image/jpeg';

      await showMediaUploadProgress(
        context: context,
        file: file,
        isVideo: isVideo,
        uploadFunction: (File fileToUpload, void Function(double progress) onProgress) async {
          final url = await chatViewModel.uploadChatMedia(
            fileToUpload.path,
            storagePath,
            contentType: contentType,
            onProgress: onProgress,
          );
          if (url == null) {
            throw Exception('Upload failed');
          }
          return url;
        },
        maxWidth: isVideo ? null : 1920,
        maxHeight: isVideo ? null : 1080,
        onComplete: (downloadUrl) async {
          if (isVideo) {
            onMediaUploaded(null, downloadUrl);
          } else {
            onMediaUploaded(downloadUrl, null);
          }

          if (context.mounted) {
            ModernSnackbar.showSuccess(
              context,
              isVideo
                  ? (AppLocalizations.of(context)?.videoSent ?? 'Video gönderildi')
                  : (AppLocalizations.of(context)?.photoSent ?? 'Fotoğraf gönderildi'),
            );
          }
        },
        onCancel: () {
          if (context.mounted) {
            ModernSnackbar.showInfo(
              context,
              AppLocalizations.of(context)?.uploadCancelled ?? 
              'Yükleme iptal edildi',
            );
          }
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      ModernSnackbar.showError(
        context,
        '${isVideo ? 'Video' : 'Resim'} gönderme hatası: ${e.toString()}',
      );
    }
  }
}

