import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';

import 'package:provider/provider.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../models/message_model.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'message_search_page.dart';
import 'message_forward_page.dart';
import 'widgets/reaction_picker.dart';
import 'widgets/message_reactions.dart';
import 'widgets/voice_message_widget.dart';
import 'widgets/file_picker_widget.dart';
import 'widgets/modern_loading_widget.dart';
import 'widgets/file_message_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../core/widgets/modern_components.dart';
import '../core/theme/app_color_config.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/audio_service.dart';

class PrivateChatPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;
  const PrivateChatPage({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController _controller = TextEditingController();
  bool _showEmojiPicker = false;
  final ImagePicker _picker = ImagePicker();
  String? _chatId;
  final ScrollController _scrollController = ScrollController();
  final AudioService _audioService = AudioService();
  
  // Pagination için
  List<MessageModel> _allMessages = [];
  bool _isLoadingOlderMessages = false;
  bool _hasMoreMessages = true;
  bool _isRecordingVoice = false;
  bool _isShowingFilePicker = false;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  bool _isInitialLoad = true;
  
  // WhatsApp tarzı ses kaydı için
  Duration _voiceRecordingDuration = Duration.zero;
  DateTime? _voiceRecordingStartTime;
  Timer? _voiceRecordingTimer;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    // Build tamamlandıktan sonra chat'i başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // En üste yaklaştığında eski mesajları yükle
      if (_scrollController.position.pixels <= 100 && 
          !_isLoadingOlderMessages && 
          _hasMoreMessages) {
        _loadOlderMessages();
      }
    });
  }

  Future<void> _initializeChat() async {
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    try {
      final chat = await chatViewModel.getOrCreatePrivateChat(
        widget.currentUserId, 
        widget.otherUserId
      );
      if (chat != null) {
        setState(() {
          _chatId = chat.id;
        });
        
        // Mesaj stream'ini başlat
        _startListeningToMessages();
      } else {
        // Hata durumunda da bir chat ID'si oluştur
        final fallbackChatId = chatViewModel.getChatId(widget.currentUserId, widget.otherUserId);
        setState(() {
          _chatId = fallbackChatId;
        });
        
        // Mesaj stream'ini başlat
        _startListeningToMessages();
      }
    } catch (e) {
      // Hata durumunda da bir chat ID'si oluştur
      final fallbackChatId = chatViewModel.getChatId(widget.currentUserId, widget.otherUserId);
      setState(() {
        _chatId = fallbackChatId;
      });
      
      // Mesaj stream'ini başlat
      _startListeningToMessages();
    }
  }

  void _startListeningToMessages() {
    if (_chatId == null) return;
    
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    _messagesSubscription?.cancel();
    _messagesSubscription = chatViewModel.getMessagesStream(_chatId!, limit: 50).listen(
      (streamMessages) {
        if (!mounted) return;
        
        // Stream'den gelen mesajları direkt kullan ve UI'ı güncelle
        final previousIds = _allMessages.map((m) => m.id).toSet();
        
        // Stream'den gelen mesajları sırala
        final sortedMessages = List<MessageModel>.from(streamMessages);
        sortedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // Yeni mesajlar var mı kontrol et
        final newMessages = sortedMessages.where((m) => !previousIds.contains(m.id)).toList();
        
        // UI'ı her zaman güncelle (stream'den gelen mesajlar güncel)
        setState(() {
          _allMessages = sortedMessages;
        });
        
        // İlk yükleme flag'ini kapat
        if (_isInitialLoad) {
          _isInitialLoad = false;
          // İlk yüklemede en alta scroll
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && _allMessages.isNotEmpty) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        } else if (newMessages.isNotEmpty) {
          // Yeni mesaj geldiğinde scroll yap
          _scrollToBottom();
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ Stream hatası: $error');
        }
        if (mounted) {
          ModernSnackbar.showError(
            context,
            AppLocalizations.of(context)?.error ?? 'Error: $error',
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _voiceRecordingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    
    // Kullanıcı en alttaysa scroll yap, değilse yapma
    final position = _scrollController.position;
    final isNearBottom = position.pixels >= position.maxScrollExtent - 100;
    
    if (isNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // Sessizce scroll yap (animasyon yok)
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Mesaj gösteriminde kullanılacak gönderen ismini döndür
  String _getDisplayName(MessageModel message) {
    // Eğer senderName "Kullanıcı" ise veya boşsa, doğru ismi kullan
    if (message.senderName == 'Kullanıcı' || message.senderName.isEmpty) {
      // Mesaj karşı taraftan geliyorsa otherUserName kullan
      if (message.senderId != widget.currentUserId) {
        return widget.otherUserName.isNotEmpty ? widget.otherUserName : 'Bilinmeyen';
      }
      // Mesaj bizden geliyorsa currentUserName kullan
      return widget.currentUserName.isNotEmpty ? widget.currentUserName : 'Ben';
    }
    // Normal durumda senderName'i kullan
    return message.senderName;
  }

  Future<void> _loadOlderMessages() async {
    if (_chatId == null || _allMessages.isEmpty) return;
    
    setState(() {
      _isLoadingOlderMessages = true;
    });

    try {
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      final oldestMessage = _allMessages.first;
      final olderMessages = await chatViewModel.loadOlderMessages(
        _chatId!,
        oldestMessage.timestamp,
        limit: 20,
      );

      if (olderMessages.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
        });
      } else {
        final scrollPosition = _scrollController.hasClients ? _scrollController.position.pixels : 0;
        setState(() {
          _allMessages = [...olderMessages, ..._allMessages];
        });
        
        // Scroll pozisyonunu koru (yeni mesajlar yüklendiğinde)
        if (_scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final newScrollPosition = _scrollController.position.maxScrollExtent - scrollPosition;
              _scrollController.jumpTo(newScrollPosition);
            }
          });
        }
      }
    } catch (e) {
      // Debug: Error loading older messages: $e
    } finally {
      setState(() {
        _isLoadingOlderMessages = false;
      });
    }
  }

  Future<void> _sendMessage({String? text, String? imageUrl, String? videoUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null && videoUrl == null) return;
    if (_chatId == null) {
      if (mounted) {
        ModernSnackbar.showError(
          context,
          AppLocalizations.of(context)?.chatStartFailed ?? 'Failed to start chat',
        );
      }
      return;
    }
    
    try {
      // Kullanıcı adını AuthViewModel'den çek (Clean Architecture)
      // widget.currentUserName "Kullanıcı" olabilir, bu yüzden her zaman Firestore'dan çekiyoruz
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      String senderName = widget.currentUserName;
      
      // Eğer currentUserName "Kullanıcı" veya boşsa, Firestore'dan çek
      if (senderName == 'Kullanıcı' || senderName.isEmpty) {
        final userProfile = await authViewModel.fetchUserProfile(widget.currentUserId);
        senderName = userProfile?.displayName ?? 'Kullanıcı';
      }
      
      // Eğer hala "Kullanıcı" ise, mevcut kullanıcının displayName'ini kullan
      if (senderName == 'Kullanıcı' && authViewModel.user != null) {
        senderName = authViewModel.user!.displayName ?? 'Kullanıcı';
      }
      
      // Mesaj tipini belirle
      MessageType messageType = MessageType.text;
      if (imageUrl != null) messageType = MessageType.image;
      if (videoUrl != null) messageType = MessageType.video;
      
      if (!mounted) return;
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      await chatViewModel.sendMessage(
        chatId: _chatId!,
        senderId: widget.currentUserId,
        senderName: senderName,
        text: text,
        type: messageType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );
      
      if (text != null) _controller.clear();
      
      // Otomatik scroll to bottom
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(
          context,
          'Mesaj gönderilemedi: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    if (!mounted || _chatId == null) return;
    
    try {
      final picked = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      
      final file = File(picked.path);
      
      // Dosya kontrolü
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.fileNotFound ?? 'File not found'),
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
        if (mounted) {
          ModernSnackbar.showError(
            context,
            AppLocalizations.of(context)?.fileTooLarge ?? 'File too large (Max: 50MB)',
          );
        }
        return;
      }
      
      // Loading göstergesi göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: ModernLoadingWidget(size: 20, showMessage: false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${isVideo ? 'Video' : 'Resim'} yükleniyor...'),
                ),
              ],
            ),
            duration: const Duration(seconds: 60),
          ),
        );
      }
      
      if (!mounted) return;
      // Context'i async işlemden önce al
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      final ext = isVideo ? 'mp4' : 'jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_media')
          .child('${DateTime.now().millisecondsSinceEpoch}.$ext');
      
      final uploadTask = ref.putFile(file);
      
      // Upload progress dinle
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (kDebugMode) {
          debugPrint('${isVideo ? 'Video' : 'Resim'} yükleme ilerlemesi: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });
      
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      
      // Başarılı mesajı göster
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${isVideo ? 'Video' : 'Resim'} yüklendi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      if (isVideo) {
        await _sendMessage(videoUrl: url);
      } else {
        await _sendMessage(imageUrl: url);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isVideo ? 'Video' : 'Resim'} gönderme hatası: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      if (kDebugMode) {
        debugPrint('${isVideo ? 'Video' : 'Resim'} gönderme hatası: $e');
      }
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    _controller.text += emoji.emoji;
    setState(() {});
  }

  Widget _buildTextMessage(MessageModel message, bool isMe) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.grey[300],
                backgroundImage: message.senderPhotoUrl != null 
                    ? NetworkImage(message.senderPhotoUrl!)
                    : null,
                child: message.senderPhotoUrl == null
                    ? Text(
                        _getDisplayName(message).isNotEmpty 
                            ? _getDisplayName(message)[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? theme.colorScheme.onSurface
                              : Colors.black87,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: isDark
                  ? ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColorConfig.primaryColor.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 20),
                            ),
                            border: Border.all(
                              color: isMe
                                  ? AppColorConfig.primaryColor.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildMessageContent(message, isMe, isDark, theme),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe ? AppColorConfig.primaryColor : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isMe ? 20 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildMessageContent(message, isMe, isDark, theme),
                    ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? theme.colorScheme.primaryContainer
                    : AppColorConfig.primaryColor.withAlpha(AppTheme.alphaLight),
                child: Text(
                  widget.currentUserName.isNotEmpty 
                      ? widget.currentUserName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? theme.colorScheme.onPrimaryContainer
                        : AppColorConfig.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(MessageModel message, bool isMe, bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe) ...[
          Text(
            _getDisplayName(message),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark
                  ? theme.colorScheme.primary
                  : AppColorConfig.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          message.text ?? '',
          style: TextStyle(
            color: isMe
                ? (isDark ? theme.colorScheme.onPrimary : Colors.white)
                : (isDark ? theme.colorScheme.onSurface : Colors.black87),
            fontSize: 16,
          ),  
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatMessageTime(message.timestamp),
              style: TextStyle(
                color: isMe
                    ? (isDark ? theme.colorScheme.onPrimary.withValues(alpha: 0.8) : Colors.white70)
                    : (isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey[600]),
                fontSize: 11,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                _getMessageStatusIcon(message.status),
                size: 12,
                color: isDark
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                    : Colors.white70,
              ),
            ],
          ],
        ),
        // Tepkiler
        MessageReactions(
          reactions: message.reactions,
          currentUserId: widget.currentUserId,
          onReactionTap: (emoji) => _handleReactionTap(message, emoji),
        ),
      ],
    );
  }

  Widget _buildImageMessage(MessageModel message, bool isMe) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.grey[300],
              backgroundImage: message.senderPhotoUrl != null 
                  ? NetworkImage(message.senderPhotoUrl!)
                  : null,
              child: message.senderPhotoUrl == null
                  ? Text(
                      message.senderName.isNotEmpty 
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : Colors.black87,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Text(
                    _getDisplayName(message),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark
                          ? theme.colorScheme.primary
                          : Colors.deepPurple[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                isDark
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                message.imageUrl!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Center(
                                      child: ModernLoadingWidget(size: 32, showMessage: false),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Icon(Icons.error, color: theme.colorScheme.error),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message.imageUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: ModernLoadingWidget(size: 32, showMessage: false),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    color: isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                // Tepkiler
                MessageReactions(
                  reactions: message.reactions,
                  currentUserId: widget.currentUserId,
                  onReactionTap: (emoji) => _handleReactionTap(message, emoji),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? theme.colorScheme.primaryContainer
                  : AppColorConfig.primaryColor.withAlpha(AppTheme.alphaLight),
              child: Text(
                widget.currentUserName.isNotEmpty 
                    ? widget.currentUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? theme.colorScheme.onPrimaryContainer
                      : AppColorConfig.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoMessage(MessageModel message, bool isMe) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.grey[300],
              backgroundImage: message.senderPhotoUrl != null 
                  ? NetworkImage(message.senderPhotoUrl!)
                  : null,
              child: message.senderPhotoUrl == null
                  ? Text(
                      message.senderName.isNotEmpty 
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : Colors.black87,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Text(
                    _getDisplayName(message),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark
                          ? theme.colorScheme.primary
                          : Colors.deepPurple[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                isDark
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _VideoMessageWidget(videoUrl: message.videoUrl!),
                            ),
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _VideoMessageWidget(videoUrl: message.videoUrl!),
                      ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    color: isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                // Tepkiler
                MessageReactions(
                  reactions: message.reactions,
                  currentUserId: widget.currentUserId,
                  onReactionTap: (emoji) => _handleReactionTap(message, emoji),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? theme.colorScheme.primaryContainer
                  : AppColorConfig.primaryColor.withAlpha(AppTheme.alphaLight),
              child: Text(
                widget.currentUserName.isNotEmpty 
                    ? widget.currentUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? theme.colorScheme.onPrimaryContainer
                      : AppColorConfig.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioMessage(MessageModel message, bool isMe) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final duration = message.metadata?['duration'] != null 
        ? Duration(milliseconds: message.metadata!['duration'])
        : null;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.grey[300],
                backgroundImage: message.senderPhotoUrl != null 
                    ? NetworkImage(message.senderPhotoUrl!)
                    : null,
                child: message.senderPhotoUrl == null
                    ? Text(
                        _getDisplayName(message).isNotEmpty 
                            ? _getDisplayName(message)[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? theme.colorScheme.onSurface
                              : Colors.black87,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Container(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark
                            ? theme.colorScheme.primary
                            : AppColorConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  VoiceMessageWidget(
                    audioUrl: message.audioUrl!,
                    duration: duration,
                    isMe: isMe,
                    onLongPress: () => _showMessageOptions(message),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  // Tepkiler
                  MessageReactions(
                    reactions: message.reactions,
                    currentUserId: widget.currentUserId,
                    onReactionTap: (emoji) => _handleReactionTap(message, emoji),
                  ),
                ],
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? theme.colorScheme.primaryContainer
                    : AppColorConfig.primaryColor.withAlpha(AppTheme.alphaLight),
                child: Text(
                  widget.currentUserName.isNotEmpty 
                      ? widget.currentUserName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? theme.colorScheme.onPrimaryContainer
                        : AppColorConfig.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage(MessageModel message, bool isMe) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final fileExtension = message.metadata?['fileExtension'] as String?;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.grey[300],
                backgroundImage: message.senderPhotoUrl != null 
                    ? NetworkImage(message.senderPhotoUrl!)
                    : null,
                child: message.senderPhotoUrl == null
                    ? Text(
                        _getDisplayName(message).isNotEmpty 
                            ? _getDisplayName(message)[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? theme.colorScheme.onSurface
                              : Colors.black87,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Container(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark
                            ? theme.colorScheme.primary
                            : AppColorConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  FileMessageWidget(
                    fileName: message.fileName ?? 'Bilinmeyen dosya',
                    fileUrl: message.fileUrl,
                    fileSize: message.fileSize,
                    fileExtension: fileExtension,
                    isMe: isMe,
                    onTap: () {
                      // Dosya açma/indirme özelliği gelecek versiyonda eklenecek
                      ModernSnackbar.showInfo(
                        context,
                        'Dosya açma özelliği yakında eklenecek',
                      );
                    },
                    onLongPress: () => _showMessageOptions(message),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  // Tepkiler
                  MessageReactions(
                    reactions: message.reactions,
                    currentUserId: widget.currentUserId,
                    onReactionTap: (emoji) => _handleReactionTap(message, emoji),
                  ),
                ],
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? theme.colorScheme.primaryContainer
                    : AppColorConfig.primaryColor.withAlpha(AppTheme.alphaLight),
                child: Text(
                  widget.currentUserName.isNotEmpty 
                      ? widget.currentUserName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? theme.colorScheme.onPrimaryContainer
                        : AppColorConfig.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  void _showMessageOptions(MessageModel message) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    GlassModalBottomSheet.show(
      context: context,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // React
          ListTile(
            leading: Icon(
              Icons.emoji_emotions,
              color: Colors.orange,
            ),
            title: Text(
              AppLocalizations.of(context)?.react ?? 'React',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showReactionPicker(message);
            },
          ),
          // Forward
          ListTile(
            leading: Icon(
              Icons.forward,
              color: Colors.deepPurple,
            ),
            title: Text(
              AppLocalizations.of(context)?.forward ?? 'Forward',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageForwardPage(message: message),
                ),
              );
            },
          ),
          // Copy
          ListTile(
            leading: Icon(
              Icons.copy,
              color: Colors.blue,
            ),
            title: Text(
              AppLocalizations.of(context)?.copy ?? 'Copy',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              if (message.text != null) {
                Clipboard.setData(ClipboardData(text: message.text!));
                ModernSnackbar.showSuccess(
                  context,
                  AppLocalizations.of(context)?.messageCopied ?? 'Message copied',
                );
              }
            },
          ),
          // Edit & Delete (only for own messages)
          if (message.senderId == widget.currentUserId) ...[
            ListTile(
              leading: Icon(
                Icons.edit,
                color: Colors.orange,
              ),
              title: Text(
                AppLocalizations.of(context)?.edit ?? 'Edit',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _editMessage(message);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title: Text(
                AppLocalizations.of(context)?.delete ?? 'Delete',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  void _editMessage(MessageModel message) {
    final controller = TextEditingController(text: message.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.editMessageTitle ?? 'Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)?.editMessageHint ?? 'Edit your message...',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (controller.text.trim().isNotEmpty) {
                try {
                  // Context'i async öncesi sakla
                  final currentContext = context;
                  final chatViewModel = Provider.of<ChatViewModel>(currentContext, listen: false);
                  await chatViewModel.editMessage(message.id, controller.text.trim());
                  if (!mounted) return;
                  navigator.pop();
                    // ignore: use_build_context_synchronously
                    ModernSnackbar.showSuccess(
                      currentContext,
                      'Mesaj düzenlendi',
                  );
                } catch (e) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  final errorContext = context;
                  ModernSnackbar.showError(
                    errorContext,
                    'Hata: $e',
                  );
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.deleteMessageTitle ?? 'Delete Message'),
        content: Text(AppLocalizations.of(context)?.deleteMessageConfirm ?? 'Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              try {
                // Context'i async öncesi sakla
                final currentContext = context;
                final chatViewModel = Provider.of<ChatViewModel>(currentContext, listen: false);
                await chatViewModel.deleteMessage(message.id, widget.currentUserId);
                if (!mounted) return;
                navigator.pop();
                // ignore: use_build_context_synchronously
                ModernSnackbar.showSuccess(
                  currentContext,
                  'Mesaj silindi',
                );
              } catch (e) {
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                final errorContext = context;
                ModernSnackbar.showError(
                  errorContext,
                  'Hata: $e',
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _handleReactionTap(MessageModel message, String emoji) async {
    try {
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      // Kullanıcının bu tepkiyi daha önce verip vermediğini kontrol et
      final userReactions = message.reactions[widget.currentUserId] ?? [];
      
      if (userReactions.contains(emoji)) {
        // Tepkiyi kaldır
        await chatViewModel.removeReaction(message.id, widget.currentUserId, emoji);
      } else {
        // Tepkiyi ekle
        await chatViewModel.addReaction(message.id, widget.currentUserId, emoji);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tepki hatası: $e')),
      );
    }
  }

  void _showReactionPicker(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactionPicker(
        onReactionSelected: (emoji) => _handleReactionTap(message, emoji),
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _sendVoiceMessage(String filePath, Duration duration) async {
    if (!mounted || _chatId == null) return;
    
    // Loading göstergesi göster
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Sesli mesaj yükleniyor...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // Dosya kontrolü
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Ses dosyası bulunamadı');
      }

      // Ses dosyasını Firebase Storage'a yükle
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_messages')
          .child('${DateTime.now().millisecondsSinceEpoch}.m4a');
      
      final uploadTask = storageRef.putFile(file);
      
      // Upload progress dinle
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (kDebugMode) {
          debugPrint('Ses yükleme ilerlemesi: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });
      
      final snapshot = await uploadTask;
      final audioUrl = await snapshot.ref.getDownloadURL();

      if (!mounted) return;
      // Kullanıcı adını AuthViewModel'den çek (Clean Architecture)
      // Context'i async işlemden önce al
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      String senderName = widget.currentUserName;
      // Eğer currentUserName "Kullanıcı" veya boşsa, Firestore'dan çek
      if (senderName == 'Kullanıcı' || senderName.isEmpty) {
        final userProfile = await authViewModel.fetchUserProfile(widget.currentUserId);
        senderName = userProfile?.displayName ?? 'Kullanıcı';
      }
      // Eğer hala "Kullanıcı" ise, mevcut kullanıcının displayName'ini kullan
      if (senderName == 'Kullanıcı' && authViewModel.user != null) {
        senderName = authViewModel.user!.displayName ?? 'Kullanıcı';
      }
      
      // Mesajı gönder
      if (!mounted) return;
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      await chatViewModel.sendVoiceMessage(
        chatId: _chatId!,
        senderId: widget.currentUserId,
        senderName: senderName,
        senderPhotoUrl: null,
        audioUrl: audioUrl,
        duration: duration,
      );

      // Başarılı mesajı göster
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Sesli mesaj gönderildi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sesli mesaj gönderme hatası: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      if (kDebugMode) {
        debugPrint('Sesli mesaj gönderme hatası: $e');
      }
    }
  }

  // Voice recording (hold to record)
  
  Future<void> _startVoiceRecording() async {
    try {
      final success = await _audioService.startRecording();
      if (success) {
        setState(() {
          _isRecordingVoice = true;
          _voiceRecordingDuration = Duration.zero;
          _voiceRecordingStartTime = DateTime.now();
        });
        
        // Süre sayacını başlat
        _voiceRecordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _isRecordingVoice) {
            setState(() {
              _voiceRecordingDuration = DateTime.now().difference(_voiceRecordingStartTime!);
            });
          }
        });
        
        // Haptic feedback
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(context, 'Ses kaydı başlatılamadı: $e');
      }
    }
  }
  
  Future<void> _stopAndSendVoiceRecording() async {
    if (!_isRecordingVoice) return;
    
    _voiceRecordingTimer?.cancel();
    
    // Minimum 1 saniye kayıt olmalı
    if (_voiceRecordingDuration.inSeconds < 1) {
      await _audioService.cancelRecording();
      setState(() {
        _isRecordingVoice = false;
        _voiceRecordingDuration = Duration.zero;
      });
      if (mounted) {
        ModernSnackbar.showInfo(context, 'Çok kısa, daha uzun basılı tutun');
      }
      return;
    }
    
    try {
      final filePath = await _audioService.stopRecording();
      if (filePath != null) {
        // Haptic feedback
        HapticFeedback.lightImpact();
        
        await _sendVoiceMessage(filePath, _voiceRecordingDuration);
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(context, 'Ses kaydı gönderilemedi: $e');
      }
    } finally {
      setState(() {
        _isRecordingVoice = false;
        _voiceRecordingDuration = Duration.zero;
      });
    }
  }
  
  Future<void> _cancelVoiceRecording() async {
    _voiceRecordingTimer?.cancel();
    await _audioService.cancelRecording();
    
    setState(() {
      _isRecordingVoice = false;
      _voiceRecordingDuration = Duration.zero;
    });
    
    HapticFeedback.lightImpact();
  }
  
  String _formatRecordingDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  Widget _buildModernMessageInputBar() {
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
        // Glassmorphism background
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
      child: _isRecordingVoice 
          ? _buildVoiceRecordingOverlay(isDark, theme)
          : _buildNormalInputBar(isDark, theme),
    );
  }
  
  Widget _buildVoiceRecordingOverlay(bool isDark, ThemeData theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.2),
            Colors.red.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // İptal butonu
          GestureDetector(
            onTap: _cancelVoiceRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Kayıt animasyonu
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Süre
          Text(
            _formatRecordingDuration(_voiceRecordingDuration),
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          
          const Spacer(),
          
          // "Bırak ve Gönder" yazısı
          Text(
            '◀ Bırak ve gönder',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          
          // Mikrofon ikonu (aktif)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 24,
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
        // Emoji butonu
        IconButton(
          icon: Icon(
            _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
          onPressed: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
        ),
        
        // Ek dosya butonu
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
                _pickMedia(ImageSource.gallery, isVideo: false);
                break;
              case 'video':
                _pickMedia(ImageSource.gallery, isVideo: true);
                break;
              case 'camera':
                _pickMedia(ImageSource.camera, isVideo: false);
                break;
              case 'file':
                _showFilePicker();
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
        
        // Mesaj giriş alanı
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
              controller: _controller,
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
        
        // Gönder veya Mikrofon butonu
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            final hasText = value.text.trim().isNotEmpty;
            
            if (hasText) {
              // Gönder butonu
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _sendMessage(text: _controller.text);
                      _scrollToBottom();
                    },
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
              // Mikrofon butonu - WhatsApp tarzı basılı tut
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onLongPressStart: (_) => _startVoiceRecording(),
                  onLongPressEnd: (_) => _stopAndSendVoiceRecording(),
                  onLongPressCancel: () => _cancelVoiceRecording(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic_rounded,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      size: 24,
                    ),
                  ),
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

  Future<void> _sendFileMessage(PlatformFile file) async {
    if (!mounted || _chatId == null) return;
    
    // Null kontrolü
    if (file.path == null || file.path!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya yolu bulunamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Dosya boyutu kontrolü (max 50MB)
    const maxFileSize = 50 * 1024 * 1024; // 50MB
    if (file.size > maxFileSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya boyutu çok büyük (Max: 50MB)'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Loading göstergesi göster
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
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
                child: Text('${file.name} yükleniyor...'),
              ),
            ],
          ),
          duration: const Duration(seconds: 60),
        ),
      );
    }

    try {
      // Dosya kontrolü
      final fileObj = File(file.path!);
      if (!await fileObj.exists()) {
        throw Exception('Dosya bulunamadı');
      }

      // Dosyayı Firebase Storage'a yükle
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_files')
          .child('${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      
      final uploadTask = storageRef.putFile(fileObj);
      
      // Upload progress dinle
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (kDebugMode) {
          debugPrint('Dosya yükleme ilerlemesi: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });
      
      final snapshot = await uploadTask;
      final fileUrl = await snapshot.ref.getDownloadURL();

      // Dosya uzantısını al
      final fileExtension = file.extension;

      if (!mounted) return;
      // Context'i async işlemden önce al
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      // Kullanıcı adını Firestore'dan çek (Clean Architecture: AuthViewModel kullan)
      String senderName = widget.currentUserName;
      if (senderName == 'Kullanıcı' || senderName.isEmpty) {
        final userProfile = await authViewModel.fetchUserProfile(widget.currentUserId);
        senderName = userProfile?.displayName ?? widget.currentUserName;
      }
      
      // Mesajı gönder
      if (!mounted) return;
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      await chatViewModel.sendFileMessage(
        chatId: _chatId!,
        senderId: widget.currentUserId,
        senderName: senderName,
        senderPhotoUrl: null,
        fileUrl: fileUrl,
        fileName: file.name,
        fileSize: file.size,
        fileExtension: fileExtension,
      );

      // Başarılı mesajı göster
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${file.name} gönderildi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dosya gönderme hatası: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      if (kDebugMode) {
        debugPrint('Dosya gönderme hatası: $e');
      }
    }
  }

  void _showFilePicker() {
    setState(() {
      _isShowingFilePicker = true;
    });
  }

  void _hideFilePicker() {
    setState(() {
      _isShowingFilePicker = false;
    });
  }

  @override
  Widget 
  
  
  build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageSearchPage(
                    chatId: _chatId,
                    chatName: widget.otherUserName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _allMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)?.noMessagesYet ?? 'No messages yet'),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)?.sendFirstMessage ?? 'Send the first message!'),
                      ],
                    ),
                  )
                : ListView.builder(
                            controller: _scrollController,
                            reverse: false, // Normal sıralama (en eski üstte, en yeni altta)
                            padding: const EdgeInsets.all(16),
                            itemCount: _allMessages.length + (_isLoadingOlderMessages ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Loading indicator for older messages (en üstte)
                              if (index == 0 && _isLoadingOlderMessages) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              
                            final messageIndex = _isLoadingOlderMessages ? index - 1 : index;
                            final message = _allMessages[messageIndex];
                            
                            // Silinen mesajları göster
                            if (message.isDeleted) {
                              return const SizedBox.shrink();
                            }
                            
                            final isMe = message.senderId == widget.currentUserId;
                          
                          if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
                            // Fotoğraf mesajı
                            return _buildImageMessage(message, isMe);
                          } else if (message.videoUrl != null && message.videoUrl!.isNotEmpty) {
                            // Video mesajı
                            return _buildVideoMessage(message, isMe);
                          } else if (message.audioUrl != null && message.audioUrl!.isNotEmpty) {
                            // Sesli mesaj
                            return _buildAudioMessage(message, isMe);
                          } else if (message.fileUrl != null && message.fileUrl!.isNotEmpty) {
                            // Dosya mesajı
                            return _buildFileMessage(message, isMe);
                          } else {
                            // Metin mesajı
                            return _buildTextMessage(message, isMe);
                          }
                        },
                      ),
          ),
          // Modern Dark Message Input Bar
          _buildModernMessageInputBar(),
          if (_showEmojiPicker)
            SizedBox(
              height: 280,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
                config: const Config(),
              ),
            ),
          if (_isShowingFilePicker)
            Container(
              padding: const EdgeInsets.all(16),
              child: FilePickerWidget(
                onFileSelected: _sendFileMessage,
                onClose: _hideFilePicker,
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoMessageWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoMessageWidget({required this.videoUrl});

  @override
  State<_VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<_VideoMessageWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() { _initialized = true; });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: _initialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_controller),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                  Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                    ),
                  ),
                ],
              ),
            )
          : Center(child: ModernLoadingWidget(message: AppLocalizations.of(context)?.loading ?? 'Loading...')),
    );
  }
} 