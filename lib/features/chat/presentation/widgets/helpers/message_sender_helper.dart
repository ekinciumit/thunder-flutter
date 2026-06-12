import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../../../core/widgets/modern_components.dart';
import '../../../../../l10n/app_localizations.dart';

/// Helper class for sending different types of messages
class MessageSenderHelper {
  /// Get sender name from AuthViewModel
  static Future<String> getSenderName({
    required BuildContext context,
    required String currentUserId,
    required String currentUserName,
  }) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    String senderName = currentUserName;
    
    // If currentUserName is "Kullanıcı" or empty, fetch from Firestore
    if (senderName == 'Kullanıcı' || senderName.isEmpty) {
      final userProfile = await authViewModel.fetchUserProfile(currentUserId);
      senderName = userProfile?.displayName ?? 'Kullanıcı';
    }
    
    // If still "Kullanıcı", use current user's displayName
    if (senderName == 'Kullanıcı' && authViewModel.user != null) {
      senderName = authViewModel.user!.displayName ?? 'Kullanıcı';
    }
    
    return senderName;
  }

  /// Send text/image/video message
  static Future<void> sendMessage({
    required BuildContext context,
    required String chatId,
    required String currentUserId,
    required String currentUserName,
    required ChatViewModel chatViewModel,
    String? text,
    String? imageUrl,
    String? videoUrl,
    required VoidCallback onSuccess,
  }) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null && videoUrl == null) {
      return;
    }
    
    try {
      final senderName = await getSenderName(
        context: context,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      );
      
      if (!context.mounted) return;
      
      // Determine message type
      MessageType messageType = MessageType.text;
      if (imageUrl != null) {
        messageType = MessageType.image;
      } else if (videoUrl != null) {
        messageType = MessageType.video;
      }
      
      await chatViewModel.sendMessage(
        chatId: chatId,
        senderId: currentUserId,
        senderName: senderName,
        text: text,
        type: messageType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );
      
      onSuccess();
    } catch (e) {
      if (context.mounted) {
        ModernSnackbar.showError(
          context,
          'Mesaj gönderilemedi: ${e.toString()}',
        );
      }
    }
  }

  /// Send voice message
  static Future<void> sendVoiceMessage({
    required BuildContext context,
    required String chatId,
    required String currentUserId,
    required String currentUserName,
    required ChatViewModel chatViewModel,
    required String filePath,
    required Duration duration,
    required VoidCallback onSuccess,
  }) async {
    if (!context.mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(l10n.voiceMessageUploading),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      final senderName = await getSenderName(
        context: context,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      );
      
      if (!context.mounted) return;

      // Check file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Ses dosyası bulunamadı');
      }

      // Upload voice message
      if (kDebugMode) {
        debugPrint('📤 [MESSAGE_SENDER] Upload başlatılıyor: $filePath');
      }
      final audioUrl = await chatViewModel.uploadVoiceMessage(
        filePath,
        chatId: chatId,
        senderId: currentUserId,
      );
      
      if (kDebugMode) {
        debugPrint('📤 [MESSAGE_SENDER] Upload tamamlandı, audioUrl: $audioUrl');
      }
      
      if (audioUrl == null) {
        if (kDebugMode) {
          debugPrint('❌ [MESSAGE_SENDER] Upload başarısız, audioUrl null');
        }
        throw Exception('Ses dosyası yüklenemedi');
      }
      
      // Send message
      if (!context.mounted) {
        if (kDebugMode) {
          debugPrint('⚠️ [MESSAGE_SENDER] Context mounted değil, return');
        }
        return;
      }
      
      if (kDebugMode) {
        debugPrint('📨 [MESSAGE_SENDER] sendVoiceMessage çağrılıyor...');
        debugPrint('📨 [MESSAGE_SENDER] chatId: $chatId');
        debugPrint('📨 [MESSAGE_SENDER] duration: ${duration.inMilliseconds}ms');
      }
      
      await chatViewModel.sendVoiceMessage(
        chatId: chatId,
        senderId: currentUserId,
        senderName: senderName,
        senderPhotoUrl: null,
        audioUrl: audioUrl,
        duration: duration,
      );
      
      if (kDebugMode) {
        debugPrint('✅ [MESSAGE_SENDER] sendVoiceMessage tamamlandı');
      }

      // Show success message
      if (context.mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.voiceMessageSent),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        onSuccess();
      }
    } catch (e) {
      if (!context.mounted) return;
      
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.voiceMessageError}: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Send file message
  static Future<void> sendFileMessage({
    required BuildContext context,
    required String chatId,
    required String currentUserId,
    required String currentUserName,
    required ChatViewModel chatViewModel,
    required PlatformFile file,
    required VoidCallback onSuccess,
  }) async {
    if (!context.mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    if (file.path == null || file.path!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileNotFound),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    const maxFileSize = 50 * 1024 * 1024;
    if (file.size > maxFileSize) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileTooLarge),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l10n.fileUploadingNamed(file.name)),
            ),
          ],
        ),
        duration: const Duration(seconds: 60),
      ),
    );

    try {
      final senderName = await getSenderName(
        context: context,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      );
      
      if (!context.mounted) return;

      // Check file exists
      final fileObj = File(file.path!);
      if (!await fileObj.exists()) {
        throw Exception('Dosya bulunamadı');
      }

      // Upload file
      final fileUrl = await chatViewModel.uploadFileMessage(
        file.path!,
        file.name,
        chatId: chatId,
        senderId: currentUserId,
      );
      
      if (fileUrl == null) {
        throw Exception('Dosya yüklenemedi');
      }

      // Get file extension
      final fileExtension = file.extension;
      
      // Send message
      if (!context.mounted) return;
      await chatViewModel.sendFileMessage(
        chatId: chatId,
        senderId: currentUserId,
        senderName: senderName,
        senderPhotoUrl: null,
        fileUrl: fileUrl,
        fileName: file.name,
        fileSize: file.size,
        fileExtension: fileExtension,
      );

      // Show success message
      if (context.mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.fileSentSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        onSuccess();
      }
    } catch (e) {
      if (!context.mounted) return;
      
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.fileSendError + ': ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

