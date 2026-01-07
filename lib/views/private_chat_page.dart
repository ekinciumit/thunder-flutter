import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../features/chat/domain/entities/message_entity.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/chat_media_handler.dart';
import '../core/widgets/modern_components.dart';
import '../l10n/app_localizations.dart';
import '../core/navigation/app_navigation.dart';
import 'widgets/helpers/voice_recording_helper.dart';
import 'widgets/helpers/message_sender_helper.dart';
import 'widgets/helpers/chat_initialization_helper.dart';
import 'widgets/helpers/chat_pagination_helper.dart';
import 'widgets/helpers/chat_message_actions_helper.dart';
import 'widgets/helpers/chat_message_formatter_helper.dart';
import 'widgets/chat_message_list_builder.dart';
import 'widgets/chat_bottom_section.dart';

class PrivateChatPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;
  final String? chatId; // Optional: if provided, use directly
  const PrivateChatPage({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserId,
    required this.otherUserName,
    this.chatId,
  });

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController _controller = TextEditingController();
  bool _showEmojiPicker = false;
  String? _chatId;
  final ScrollController _scrollController = ScrollController();
  
  // Pagination için
  List<MessageEntity> _allMessages = [];
  bool _isLoadingOlderMessages = false;
  bool _hasMoreMessages = true;
  bool _isShowingFilePicker = false;
  
  // Voice recording helper
  late final VoiceRecordingHelper _voiceRecordingHelper;
  
  // ChatViewModel referansı - dispose() içinde kullanmak için
  ChatViewModel? _chatViewModel;

  // Scroll listener callback'i sakla (dispose için)
  VoidCallback? _scrollListenerCallback;

  @override
  void initState() {
    super.initState();
    _voiceRecordingHelper = VoiceRecordingHelper();
    
    // Scroll listener callback'i oluştur ve sakla
    _scrollListenerCallback = () {
      if (_scrollController.position.pixels <= 100 &&
          !_isLoadingOlderMessages &&
          _hasMoreMessages) {
        _loadOlderMessages();
      }
    };
    
    _scrollController.addListener(_scrollListenerCallback!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeChat());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ChatViewModel referansını sakla - dispose() içinde kullanmak için
    _chatViewModel ??= Provider.of<ChatViewModel>(context, listen: false);
  }

  Future<void> _initializeChat() async {
    if (!mounted) return;
    
    final chatId = await ChatInitializationHelper.initializeChat(
      context: context,
      currentUserId: widget.currentUserId,
      otherUserId: widget.otherUserId,
      onChatIdSet: (id) {
        if (mounted) {
          setState(() => _chatId = id);
        }
      },
    );
    
    if (!mounted || chatId == null) return;
    
    ChatInitializationHelper.startListeningToMessages(
      context: context,
      chatId: chatId,
      scrollController: _scrollController,
      onMessagesLoaded: (messages) {
        // İlk yükleme - mesajları kaydet
        if (mounted) {
          setState(() {
            _allMessages = messages;
          });
          
          // İlk yüklemede son mesajlara scroll yap (WhatsApp gibi)
          // Mesajlar render edildikten sonra scroll yap
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && messages.isNotEmpty) {
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
              }
            });
          });
        }
      },
    );
  }

  @override
  void dispose() {
    // Scroll listener'ı temizle
    if (_scrollListenerCallback != null) {
      _scrollController.removeListener(_scrollListenerCallback!);
    }
    
    _voiceRecordingHelper.dispose();
    _controller.dispose();
    
    // Stop listening to messages before disposing scroll controller
    // didChangeDependencies() içinde saklanan referansı kullan
    if (_chatId != null && _chatViewModel != null) {
      try {
        _chatViewModel!.stopListeningToMessages(_chatId!);
      } catch (e) {
        // Hata durumunda sessizce devam et
        if (kDebugMode) {
          debugPrint('⚠️ [PRIVATE_CHAT] stopListeningToMessages hatası: $e');
        }
      }
    }
    
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to bottom - sadece kullanıcı en alttaysa veya yakınsa
  void _scrollToBottom({bool force = false}) {
    if (!_scrollController.hasClients) return;
    
    final position = _scrollController.position;
    final isNearBottom = position.pixels >= position.maxScrollExtent - 100;
    
    // Force: Mesaj gönderildiğinde her zaman scroll yap
    // Normal: Yeni mesaj geldiğinde sadece kullanıcı en alttaysa scroll yap
    if (force || isNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // Sessizce scroll yap (animasyon yok)
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  String _formatMessageTime(DateTime timestamp) =>
      ChatMessageFormatterHelper.formatMessageTime(timestamp);

  String _getDisplayName(MessageEntity message) =>
      ChatMessageFormatterHelper.getDisplayName(
        message: message,
        currentUserId: widget.currentUserId,
        currentUserName: widget.currentUserName,
        otherUserName: widget.otherUserName,
      );

  Future<void> _loadOlderMessages() async {
    if (_chatId == null || _allMessages.isEmpty || !mounted) return;
    
    if (!mounted) return;
    setState(() => _isLoadingOlderMessages = true);

    final result = await ChatPaginationHelper.loadOlderMessages(
      context: context,
      chatId: _chatId!,
      currentMessages: _allMessages,
      scrollController: _scrollController,
    );

    if (!mounted) return;
    setState(() {
      _allMessages = result.messages;
      _hasMoreMessages = result.hasMore;
      _isLoadingOlderMessages = false;
    });
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
    
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    
    await MessageSenderHelper.sendMessage(
      context: context,
      chatId: _chatId!,
      currentUserId: widget.currentUserId,
      currentUserName: widget.currentUserName,
      chatViewModel: chatViewModel,
      text: text,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      onSuccess: () {
        if (text != null) _controller.clear();
        _scrollToBottom(force: true); // Mesaj gönderildiğinde her zaman scroll yap
      },
    );
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    if (!mounted || _chatId == null) return;
    
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    final handler = ChatMediaHandler(
      context: context,
      chatViewModel: chatViewModel,
      authViewModel: authViewModel,
      chatId: _chatId!,
      currentUserId: widget.currentUserId,
      currentUserName: widget.currentUserName,
      onMediaUploaded: (imageUrl, videoUrl) async {
        await _sendMessage(imageUrl: imageUrl, videoUrl: videoUrl);
      },
    );
    
    await handler.pickMedia(source, isVideo: isVideo);
  }

  void _onEmojiSelected(Emoji emoji) {
    _controller.text += emoji.emoji;
    setState(() {});
  }

  void _showMessageOptions(MessageEntity message) {
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    ChatMessageActionsHelper.showMessageOptions(
      context: context,
      message: message,
      currentUserId: widget.currentUserId,
      onReact: () => ChatMessageActionsHelper.handleReactionTap(
        context: context,
        message: message,
        currentUserId: widget.currentUserId,
        chatViewModel: chatViewModel,
      ),
      onForward: () => ChatMessageActionsHelper.forwardMessage(
        context: context,
        message: message,
      ),
      onCopy: () => ChatMessageActionsHelper.copyMessage(
        context: context,
        text: message.text,
      ),
      onEdit: message.senderId == widget.currentUserId
          ? () => ChatMessageActionsHelper.editMessage(
                context: context,
                message: message,
                chatViewModel: chatViewModel,
              )
          : null,
      onDelete: message.senderId == widget.currentUserId
          ? () => ChatMessageActionsHelper.deleteMessage(
                context: context,
                message: message,
                currentUserId: widget.currentUserId,
                chatViewModel: chatViewModel,
              )
          : null,
    );
  }

  void _handleReactionTap(MessageEntity message, String emoji) async {
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    await ChatMessageActionsHelper.handleReactionTap(
      context: context,
      message: message,
      currentUserId: widget.currentUserId,
      chatViewModel: chatViewModel,
    );
  }

  Future<void> _sendVoiceMessage(String filePath, Duration duration) async {
    if (kDebugMode) {
      debugPrint('📞 [PRIVATE_CHAT] _sendVoiceMessage çağrıldı');
      debugPrint('📞 [PRIVATE_CHAT] filePath: $filePath');
      debugPrint('📞 [PRIVATE_CHAT] duration: ${duration.inMilliseconds}ms');
      debugPrint('📞 [PRIVATE_CHAT] mounted: $mounted, chatId: $_chatId');
    }
    
    if (!mounted || _chatId == null) {
      if (kDebugMode) {
        debugPrint('⚠️ [PRIVATE_CHAT] mounted: $mounted, chatId: $_chatId - return');
      }
      return;
    }
    
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    
    await MessageSenderHelper.sendVoiceMessage(
      context: context,
      chatId: _chatId!,
      currentUserId: widget.currentUserId,
      currentUserName: widget.currentUserName,
      chatViewModel: chatViewModel,
      filePath: filePath,
      duration: duration,
      onSuccess: () => _scrollToBottom(force: true), // Mesaj gönderildiğinde her zaman scroll yap
    );
    
    if (kDebugMode) {
      debugPrint('✅ [PRIVATE_CHAT] _sendVoiceMessage tamamlandı');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WHATSAPP TARZI SES KAYDI - BASILI TUT VE BIRAK
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _startVoiceRecording() async {
    if (kDebugMode) {
      debugPrint('🎯 [PRIVATE_CHAT] _startVoiceRecording çağrıldı');
    }
    await _voiceRecordingHelper.startRecording(
      onStateChanged: () => setState(() {}),
      context: context,
    );
    if (kDebugMode) {
      debugPrint('🎯 [PRIVATE_CHAT] _startVoiceRecording tamamlandı');
    }
  }
  
  Future<void> _stopAndSendVoiceRecording() async {
    await _voiceRecordingHelper.stopRecording(
      onSend: _sendVoiceMessage,
      context: context,
      onStateChanged: () => setState(() {}),
    );
  }
  
  Future<void> _cancelVoiceRecording() async {
    await _voiceRecordingHelper.cancelRecording(
      onStateChanged: () => setState(() {}),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MODERN MESAJ GİRİŞ BARI
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _sendFileMessage(PlatformFile file) async {
    if (!mounted || _chatId == null) return;
    
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    
    await MessageSenderHelper.sendFileMessage(
      context: context,
      chatId: _chatId!,
      currentUserId: widget.currentUserId,
      currentUserName: widget.currentUserName,
      chatViewModel: chatViewModel,
      file: file,
      onSuccess: () => _scrollToBottom(force: true), // Mesaj gönderildiğinde her zaman scroll yap
    );
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

  /// Kullanıcı profiline git
  Future<void> _navigateToUserProfile(String userId) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userProfile = await authViewModel.fetchUserProfile(userId);
    
    if (userProfile != null && mounted) {
      AppNavigation.toUserProfile(context: context, userId: userProfile.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        otherUserId: widget.otherUserId,
        otherUserName: widget.otherUserName,
        chatId: _chatId,
        onUserProfileTap: () => _navigateToUserProfile(widget.otherUserId),
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessageListBuilder(
              chatId: _chatId,
              currentUserId: widget.currentUserId,
              currentUserName: widget.currentUserName,
              scrollController: _scrollController,
              isLoadingOlderMessages: _isLoadingOlderMessages,
              getDisplayName: _getDisplayName,
              formatMessageTime: _formatMessageTime,
              onLongPress: _showMessageOptions,
              onReactionTap: _handleReactionTap,
              onScrollToBottom: _scrollToBottom,
              onMessagesUpdated: (messages) {
                // Sadece gerçekten değişiklik varsa setState yap
                final currentIds = _allMessages.map((m) => m.id).toSet();
                final newIds = messages.map((m) => m.id).toSet();
                if (currentIds != newIds || messages.length != _allMessages.length) {
                  setState(() {
                    _allMessages = messages;
                  });
                }
              },
            ),
          ),
          ChatBottomSection(
            textController: _controller,
            showEmojiPicker: _showEmojiPicker,
            isShowingFilePicker: _isShowingFilePicker,
            voiceRecordingHelper: _voiceRecordingHelper,
            onEmojiPickerToggle: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
            onSendTextMessage: () {
              _sendMessage(text: _controller.text);
              // _scrollToBottom() zaten onSuccess callback'inde force: true ile çağrılıyor
            },
            onVoiceRecordingCancel: _cancelVoiceRecording,
            onVoiceRecordingStopAndSend: _stopAndSendVoiceRecording,
            onVoiceRecordingStart: () {
              _voiceRecordingHelper.resetSwipeState(() => setState(() {}));
              _startVoiceRecording();
            },
            onVoiceRecordingSwipeUpdate: (offset, isCancelling) {
              _voiceRecordingHelper.updateSwipeOffset(offset, isCancelling, () => setState(() {}));
            },
            onPickMedia: (source, {isVideo = false}) => _pickMedia(source, isVideo: isVideo),
            onShowFilePicker: _showFilePicker,
            onEmojiPickerChanged: (show) => setState(() => _showEmojiPicker = show),
            onEmojiSelected: _onEmojiSelected,
            onFileSelected: _sendFileMessage,
            onHideFilePicker: _hideFilePicker,
          ),
        ],
      ),
    );
  }
}