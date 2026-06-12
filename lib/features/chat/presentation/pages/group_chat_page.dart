import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/chat_message_list_builder.dart';
import '../widgets/chat_bottom_section.dart';
import '../widgets/helpers/voice_recording_helper.dart';
import '../widgets/helpers/message_sender_helper.dart';
import '../widgets/helpers/chat_message_actions_helper.dart';
import '../widgets/helpers/chat_message_formatter_helper.dart';
import '../widgets/chat_media_handler.dart';
import '../widgets/mute_chat_dialog.dart';
import '../widgets/helpers/chat_initialization_helper.dart';

/// Group Chat Page
/// 
/// Grup sohbeti için sayfa
class GroupChatPage extends StatefulWidget {
  final String chatId;
  final String? groupName;
  final String? groupPhotoUrl;
  
  const GroupChatPage({
    super.key,
    required this.chatId,
    this.groupName,
    this.groupPhotoUrl,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmojiPicker = false;
  bool _isShowingFilePicker = false;
  late final VoiceRecordingHelper _voiceRecordingHelper;
  ChatViewModel? _chatViewModel;
  Stream<ChatEntity?>? _chatStream;
  
  List<MessageEntity> _allMessages = [];
  final bool _isLoadingOlderMessages = false;

  @override
  void initState() {
    super.initState();
    _voiceRecordingHelper = VoiceRecordingHelper();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeChat());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatViewModel ??= Provider.of<ChatViewModel>(context, listen: false);
    _chatStream ??= _chatViewModel!.getChatStream(widget.chatId);
  }

  @override
  void dispose() {
    if (_chatViewModel != null) {
      try {
        _chatViewModel!.stopListeningToMessages(widget.chatId);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [GROUP_CHAT] stopListeningToMessages hatası: $e');
        }
      }
    }
    _controller.dispose();
    _scrollController.dispose();
    _voiceRecordingHelper.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (!mounted) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.user == null) return;

    ChatInitializationHelper.startListeningToMessages(
      context: context,
      chatId: widget.chatId,
      scrollController: _scrollController,
      onMessagesLoaded: (messages) {
        if (!mounted) return;
        setState(() => _allMessages = messages);
      },
    );
  }

  String _getDisplayName(MessageEntity message) {
    return message.senderName;
  }

  String _formatMessageTime(DateTime timestamp) {
    return ChatMessageFormatterHelper.formatMessageTime(timestamp);
  }

  void _scrollToBottom({bool force = false}) {
    if (_scrollController.hasClients) {
      if (force) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }


  Future<void> _sendMessage({String? text, String? imageUrl, String? videoUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null && videoUrl == null) return;
    
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    
    if (currentUser == null) return;
    
    await MessageSenderHelper.sendMessage(
      context: context,
      chatId: widget.chatId,
      currentUserId: currentUser.uid,
      currentUserName: currentUser.displayName ?? 'Kullanıcı',
      chatViewModel: chatViewModel,
      text: text,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      onSuccess: () {
        if (text != null) _controller.clear();
        _scrollToBottom(force: true);
      },
    );
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    if (!mounted) return;
    
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    
    if (currentUser == null) return;
    
    final handler = ChatMediaHandler(
      context: context,
      chatViewModel: chatViewModel,
      authViewModel: authViewModel,
      chatId: widget.chatId,
      currentUserId: currentUser.uid,
      currentUserName: currentUser.displayName ?? 'Kullanıcı',
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
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    
    if (currentUser == null) return;
    
    ChatMessageActionsHelper.showMessageOptions(
      context: context,
      message: message,
      currentUserId: currentUser.uid,
      onReact: () => ChatMessageActionsHelper.handleReactionTap(
        context: context,
        message: message,
        currentUserId: currentUser.uid,
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
      onEdit: message.senderId == currentUser.uid
          ? () => ChatMessageActionsHelper.editMessage(
                context: context,
                message: message,
                chatViewModel: chatViewModel,
              )
          : null,
      onDelete: message.senderId == currentUser.uid
          ? () => ChatMessageActionsHelper.deleteMessage(
                context: context,
                message: message,
                currentUserId: currentUser.uid,
                chatViewModel: chatViewModel,
              )
          : null,
    );
  }

  Future<void> _handleReactionTap(MessageEntity message, String emoji) async {
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    
    if (currentUser == null) return;
    
    await ChatMessageActionsHelper.handleReactionTap(
      context: context,
      message: message,
      currentUserId: currentUser.uid,
      chatViewModel: chatViewModel,
    );
  }

  Future<void> _startVoiceRecording() async {
    await _voiceRecordingHelper.startRecording(
      onStateChanged: () => setState(() {}),
      context: context,
    );
  }

  Future<void> _stopAndSendVoiceRecording() async {
    await _voiceRecordingHelper.stopRecording(
      onSend: (filePath, duration) async {
        if (!mounted) return;
        
        final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        final currentUser = authViewModel.user;
        
        if (currentUser == null) return;
        
        await MessageSenderHelper.sendVoiceMessage(
          context: context,
          chatId: widget.chatId,
          currentUserId: currentUser.uid,
          currentUserName: currentUser.displayName ?? 'Kullanıcı',
          chatViewModel: chatViewModel,
          filePath: filePath,
          duration: duration,
          onSuccess: () {
            _scrollToBottom(force: true);
          },
        );
      },
      context: context,
      onStateChanged: () => setState(() {}),
    );
  }

  Future<void> _cancelVoiceRecording() async {
    await _voiceRecordingHelper.cancelRecording(
      onStateChanged: () => setState(() {}),
    );
  }

  void _onFileSelected(PlatformFile file) async {
    if (!mounted) return;
    
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    
    if (currentUser == null) return;
    
    await MessageSenderHelper.sendFileMessage(
      context: context,
      chatId: widget.chatId,
      currentUserId: currentUser.uid,
      currentUserName: currentUser.displayName ?? 'Kullanıcı',
      file: file,
      chatViewModel: chatViewModel,
      onSuccess: () {
        _scrollToBottom(force: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final currentUser = authViewModel.user;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.chat)),
        body: Center(child: Text(l10n.notLoggedIn)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<ChatEntity?>(
          stream: _chatStream,
          builder: (context, snapshot) {
            final chat = snapshot.data;
            final groupName = widget.groupName ?? chat?.name ?? l10n.chat;
            final groupPhotoUrl = widget.groupPhotoUrl ?? chat?.photoUrl;

            return GestureDetector(
              onTap: () => context.push('/chat/${widget.chatId}/info'),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: groupPhotoUrl != null && groupPhotoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(groupPhotoUrl)
                        : null,
                    backgroundColor: groupPhotoUrl == null || groupPhotoUrl.isEmpty
                        ? AppColorConfig.primaryColor
                        : null,
                    child: groupPhotoUrl == null || groupPhotoUrl.isEmpty
                        ? Icon(Icons.group_rounded, color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          groupName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (chat != null && chat.participants.isNotEmpty)
                          Text(
                            '${chat.participants.length} katılımcı',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          StreamBuilder<ChatEntity?>(
            stream: _chatStream,
            builder: (context, snapshot) {
              final currentChat = snapshot.data;
              final isMuted = currentChat?.isMutedUntil(currentUser.uid) ?? false;

              return IconButton(
                icon: Icon(
                  isMuted ? Icons.notifications_off_rounded : Icons.notifications_rounded,
                  color: isMuted ? theme.colorScheme.error : null,
                ),
                onPressed: () async {
                  if (isMuted) {
                    await chatViewModel.unmuteChat(
                      chatId: widget.chatId,
                      userId: currentUser.uid,
                    );
                    if (context.mounted) {
                      ModernSnackbar.showSuccess(context, 'Sessize alma kaldırıldı');
                    }
                  } else {
                    final selectedDuration = await MuteChatDialog.show(
                      context: context,
                      isCurrentlyMuted: isMuted,
                    );

                    if (selectedDuration != null && context.mounted) {
                      final muteUntil = MuteChatDialog.getMuteUntil(selectedDuration);
                      await chatViewModel.muteChat(
                        chatId: widget.chatId,
                        userId: currentUser.uid,
                        muteUntil: muteUntil,
                      );

                      if (context.mounted) {
                        final message = muteUntil == null
                            ? 'Sohbet süresiz sessize alındı'
                            : 'Sohbet sessize alındı';
                        ModernSnackbar.showSuccess(context, message);
                      }
                    }
                  }
                },
                tooltip: isMuted ? 'Sessize Almayı Kaldır' : 'Sessize Al',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessageListBuilder(
              key: ValueKey('group_messages_${widget.chatId}'),
              chatId: widget.chatId,
              currentUserId: currentUser.uid,
              currentUserName: currentUser.displayName ?? 'Kullanıcı',
              scrollController: _scrollController,
              isLoadingOlderMessages: _isLoadingOlderMessages,
              getDisplayName: _getDisplayName,
              formatMessageTime: _formatMessageTime,
              onLongPress: _showMessageOptions,
              onReactionTap: _handleReactionTap,
              onScrollToBottom: _scrollToBottom,
              onMessagesUpdated: (messages) {
                if (!mounted) return;
                final currentIds = _allMessages.map((m) => m.id).toSet();
                final newIds = messages.map((m) => m.id).toSet();
                if (currentIds != newIds || messages.length != _allMessages.length) {
                  setState(() => _allMessages = messages);
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
            onPickMedia: _pickMedia,
            onShowFilePicker: () => setState(() => _isShowingFilePicker = true),
            onEmojiPickerChanged: (show) => setState(() => _showEmojiPicker = show),
            onEmojiSelected: _onEmojiSelected,
            onFileSelected: _onFileSelected,
            onHideFilePicker: () => setState(() => _isShowingFilePicker = false),
          ),
        ],
      ),
    );
  }
}
