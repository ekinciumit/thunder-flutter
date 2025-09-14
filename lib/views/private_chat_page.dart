import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/chat_service.dart';

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
import 'widgets/voice_recorder_widget.dart';
import 'widgets/file_picker_widget.dart';
import 'widgets/file_message_widget.dart';
import '../services/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  final ChatService _chatService = ChatService();
  bool _showEmojiPicker = false;
  bool _isSending = false;
  final ImagePicker _picker = ImagePicker();
  String? _chatId;
  final ScrollController _scrollController = ScrollController();
  
  // Pagination için
  List<MessageModel> _allMessages = [];
  bool _isLoadingOlderMessages = false;
  bool _hasMoreMessages = true;
  bool _isRecordingVoice = false;
  bool _isShowingFilePicker = false;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _setupScrollListener();
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
    try {
      // Debug: Initializing chat for users: ${widget.currentUserId} and ${widget.otherUserId}
      final chat = await _chatService.getOrCreatePrivateChat(
        widget.currentUserId, 
        widget.otherUserId
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Debug: Chat initialization timeout
          throw Exception('Chat initialization timeout');
        },
      );
      // Debug: Chat initialized with ID: ${chat.id}
      setState(() {
        _chatId = chat.id;
      });
    } catch (e) {
      // Debug: Error initializing chat: $e
      // Hata durumunda da bir chat ID'si oluştur
      final fallbackChatId = '${widget.currentUserId}_${widget.otherUserId}';
      setState(() {
        _chatId = fallbackChatId;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottomIfNeeded() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom = position.pixels <= position.minScrollExtent + 50;

    if (isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
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

  Future<void> _loadOlderMessages() async {
    if (_chatId == null || _allMessages.isEmpty) return;
    
    setState(() {
      _isLoadingOlderMessages = true;
    });

    try {
      final oldestMessage = _allMessages.first;
      final olderMessages = await _chatService.loadOlderMessages(
        _chatId!,
        oldestMessage.timestamp,
        limit: 20,
      );

      if (olderMessages.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
        });
      } else {
        setState(() {
          _allMessages = [...olderMessages, ..._allMessages];
        });
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
      // Debug: Chat ID is null, cannot send message
      return;
    }
    
    setState(() { _isSending = true; });
    
    try {
      // Mesaj tipini belirle
      MessageType messageType = MessageType.text;
      if (imageUrl != null) messageType = MessageType.image;
      if (videoUrl != null) messageType = MessageType.video;
      
      // Debug: Sending message: $text, type: $messageType, chatId: $_chatId
      
      await _chatService.sendMessage(
        chatId: _chatId!,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        text: text,
        type: messageType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );
      
      // Debug: Message sent successfully
      setState(() { _isSending = false; });
      if (text != null) _controller.clear();
      
      // Otomatik scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottomIfNeeded();
      });
    } catch (e) {
      // Debug: Error sending message: $e
      setState(() { _isSending = false; });
    }
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    final picked = isVideo
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    final file = File(picked.path);
    final ext = isVideo ? 'mp4' : 'jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_media')
        .child('${DateTime.now().millisecondsSinceEpoch}.$ext');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();
    if (isVideo) {
      await _sendMessage(videoUrl: url);
    } else {
      await _sendMessage(imageUrl: url);
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    _controller.text += emoji.emoji;
    setState(() {});
  }

  Widget _buildTextMessage(MessageModel message, bool isMe) {
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
                backgroundColor: Colors.grey[300],
                backgroundImage: message.senderPhotoUrl != null 
                    ? NetworkImage(message.senderPhotoUrl!)
                    : null,
                child: message.senderPhotoUrl == null
                    ? Text(
                        message.senderName.isNotEmpty 
                            ? message.senderName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.deepPurple : Colors.grey[200],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe) ...[
                      Text(
                        message.senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.deepPurple[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message.text ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
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
                            color: isMe ? Colors.white70 : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            _getMessageStatusIcon(message.status),
                            size: 12,
                            color: Colors.white70,
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
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.deepPurple[100],
                backgroundImage: widget.currentUserName.isNotEmpty 
                    ? null // Kullanıcı fotoğrafı varsa buraya eklenebilir
                    : null,
                child: Text(
                  widget.currentUserName.isNotEmpty 
                      ? widget.currentUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage(MessageModel message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: message.senderPhotoUrl != null 
                  ? NetworkImage(message.senderPhotoUrl!)
                  : null,
              child: message.senderPhotoUrl == null
                  ? Text(
                      message.senderName.isNotEmpty 
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      color: Colors.deepPurple[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                ClipRRect(
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
                          child: CircularProgressIndicator(),
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
                    color: Colors.grey[600],
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
              backgroundColor: Colors.deepPurple[100],
              child: Text(
                widget.currentUserName.isNotEmpty 
                    ? widget.currentUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoMessage(MessageModel message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: message.senderPhotoUrl != null 
                  ? NetworkImage(message.senderPhotoUrl!)
                  : null,
              child: message.senderPhotoUrl == null
                  ? Text(
                      message.senderName.isNotEmpty 
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      color: Colors.deepPurple[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _VideoMessageWidget(videoUrl: message.videoUrl!),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
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
              backgroundColor: Colors.deepPurple[100],
              child: Text(
                widget.currentUserName.isNotEmpty 
                    ? widget.currentUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioMessage(MessageModel message, bool isMe) {
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
                backgroundColor: Colors.grey[300],
                backgroundImage: message.senderPhotoUrl != null 
                    ? NetworkImage(message.senderPhotoUrl!)
                    : null,
                child: message.senderPhotoUrl == null
                    ? Text(
                        message.senderName.isNotEmpty 
                            ? message.senderName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                        color: Colors.deepPurple[700],
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
                      color: Colors.grey[600],
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
                backgroundColor: Colors.deepPurple[100],
                child: Text(
                  widget.currentUserName.isNotEmpty 
                      ? widget.currentUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage(MessageModel message, bool isMe) {
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
                backgroundColor: Colors.grey[300],
                backgroundImage: message.senderPhotoUrl != null 
                    ? NetworkImage(message.senderPhotoUrl!)
                    : null,
                child: message.senderPhotoUrl == null
                    ? Text(
                        message.senderName.isNotEmpty 
                            ? message.senderName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                        color: Colors.deepPurple[700],
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
                      // TODO: Dosyayı açma/indirme işlevi
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dosya açma özelliği yakında eklenecek')),
                      );
                    },
                    onLongPress: () => _showMessageOptions(message),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
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
                backgroundColor: Colors.deepPurple[100],
                child: Text(
                  widget.currentUserName.isNotEmpty 
                      ? widget.currentUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions, color: Colors.orange),
              title: const Text('Tepki Ver'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward, color: Colors.deepPurple),
              title: const Text('İlet'),
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
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.blue),
              title: const Text('Kopyala'),
              onTap: () {
                Navigator.pop(context);
                if (message.text != null) {
                  Clipboard.setData(ClipboardData(text: message.text!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mesaj kopyalandı')),
                  );
                }
              },
            ),
            if (message.senderId == widget.currentUserId) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Sil'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _editMessage(MessageModel message) {
    final controller = TextEditingController(text: message.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Düzenle'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Mesajınızı düzenleyin...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await _chatService.editMessage(message.id, controller.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mesaj düzenlendi')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
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
        title: const Text('Mesajı Sil'),
        content: const Text('Bu mesajı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _chatService.deleteMessage(message.id, widget.currentUserId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mesaj silindi')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
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
      // Kullanıcının bu tepkiyi daha önce verip vermediğini kontrol et
      final userReactions = message.reactions[widget.currentUserId] ?? [];
      
      if (userReactions.contains(emoji)) {
        // Tepkiyi kaldır
        await _chatService.removeReaction(message.id, widget.currentUserId, emoji);
      } else {
        // Tepkiyi ekle
        await _chatService.addReaction(message.id, widget.currentUserId, emoji);
      }
    } catch (e) {
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
    try {
      if (_chatId == null) return;

      // Ses dosyasını Firebase Storage'a yükle
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_messages')
          .child('${DateTime.now().millisecondsSinceEpoch}.m4a');
      
      final uploadTask = storageRef.putFile(File(filePath));
      final snapshot = await uploadTask;
      final audioUrl = await snapshot.ref.getDownloadURL();

      // Mesajı gönder
      await _chatService.sendVoiceMessage(
        chatId: _chatId!,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        senderPhotoUrl: null, // TODO: Kullanıcı fotoğrafı ekle
        audioUrl: audioUrl,
        duration: duration,
      );

      _scrollToBottomIfNeeded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sesli mesaj gönderme hatası: $e')),
      );
    }
  }

  void _showVoiceRecorder() {
    setState(() {
      _isRecordingVoice = true;
    });
  }

  void _hideVoiceRecorder() {
    setState(() {
      _isRecordingVoice = false;
    });
  }

  Future<void> _sendFileMessage(PlatformFile file) async {
    try {
      if (_chatId == null) return;

      // Dosyayı Firebase Storage'a yükle
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_files')
          .child('${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      
      final uploadTask = storageRef.putFile(File(file.path!));
      final snapshot = await uploadTask;
      final fileUrl = await snapshot.ref.getDownloadURL();

      // Dosya uzantısını al
      final fileExtension = file.extension;

      // Mesajı gönder
      await _chatService.sendFileMessage(
        chatId: _chatId!,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        senderPhotoUrl: null, // TODO: Kullanıcı fotoğrafı ekle
        fileUrl: fileUrl,
        fileName: file.name,
        fileSize: file.size,
        fileExtension: fileExtension,
      );

      _scrollToBottomIfNeeded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya gönderme hatası: $e')),
      );
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
            child: _chatId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<MessageModel>>(
                    stream: _chatService.getMessagesStream(_chatId!, limit: 30),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Mesajlar yükleniyor...'),
                            ],
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        // Debug: Stream error: ${snapshot.error}
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Hata: ${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _chatId = null;
                                  });
                                  _initializeChat();
                                },
                                child: const Text('Tekrar Dene'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // Stream'den gelen yeni mesajları _allMessages ile birleştir
                      final streamMessages = snapshot.data ?? [];
                      if (streamMessages.isNotEmpty) {
                        // _allMessages ile stream'den gelenleri birleştir
                        final merged = {..._allMessages, ...streamMessages}.toList();
                        
                        // Tarihe göre sırala (sondan başa)
                        merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                        
                        _allMessages = merged;
                      }
                      
                      if (_allMessages.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Henüz mesaj yok'),
                              SizedBox(height: 8),
                              Text('İlk mesajı siz gönderin!'),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _allMessages.length + (_isLoadingOlderMessages ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Loading indicator for older messages
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
                          final isMe = message.senderId == widget.currentUserId;
                          
                          // Yeni mesaj geldiğinde otomatik scroll (sadece kullanıcı alttaysa)
                          if (messageIndex == _allMessages.length - 1) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToBottomIfNeeded();
                            });
                          }
                          
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
                      );
                    },
                  ),
          ),
          if (_isSending) const LinearProgressIndicator(minHeight: 2),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions, color: Colors.deepPurple),
                onPressed: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
              ),
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.deepPurple),
                onPressed: _showVoiceRecorder,
              ),
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.deepPurple),
                onPressed: _showFilePicker,
              ),
              IconButton(
                icon: const Icon(Icons.photo, color: Colors.blue),
                onPressed: () => _pickMedia(ImageSource.gallery, isVideo: false),
              ),
              IconButton(
                icon: const Icon(Icons.videocam, color: Colors.red),
                onPressed: () => _pickMedia(ImageSource.gallery, isVideo: true),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Mesaj yaz...',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.deepPurple),
                onPressed: () => _sendMessage(text: _controller.text),
              ),
            ],
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 280,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
                config: const Config(),
              ),
            ),
          if (_isRecordingVoice)
            Container(
              padding: const EdgeInsets.all(16),
              child: VoiceRecorderWidget(
                onRecordingComplete: _sendVoiceMessage,
                onCancel: _hideVoiceRecorder,
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
          : const Center(child: CircularProgressIndicator()),
    );
  }
} 