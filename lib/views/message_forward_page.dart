import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'widgets/app_gradient_container.dart';
import 'widgets/modern_loading_widget.dart';

class MessageForwardPage extends StatefulWidget {
  final MessageModel message;

  const MessageForwardPage({
    super.key,
    required this.message,
  });

  @override
  State<MessageForwardPage> createState() => _MessageForwardPageState();
}

class _MessageForwardPageState extends State<MessageForwardPage> {
  List<ChatModel> _chats = [];
  bool _isLoading = true;
  bool _isForwarding = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final currentUser = authViewModel.user;
      
      if (currentUser == null) return;

      // Kullanıcının sohbetlerini al
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      final chatsStream = chatViewModel.getUserChats(currentUser.uid);
      await for (final chats in chatsStream) {
        if (mounted) {
          setState(() {
            _chats = chats.where((chat) => chat.id != widget.message.chatId).toList();
            _isLoading = false;
          });
        }
        break; // İlk veriyi aldıktan sonra stream'i kapat
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sohbetler yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _forwardMessage(ChatModel targetChat) async {
    setState(() {
      _isForwarding = true;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final currentUser = authViewModel.user;
      
      if (currentUser == null) return;

      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      await chatViewModel.forwardMessage(
        originalMessage: widget.message,
        targetChatId: targetChat.id,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Kullanıcı',
        senderPhotoUrl: currentUser.photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesaj başarıyla iletildi')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj iletilemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isForwarding = false;
        });
      }
    }
  }

  String _getChatDisplayName(ChatModel chat, String currentUserId) {
    if (chat.type == ChatType.private) {
      // Özel sohbet için diğer kullanıcının adını bul
      final otherParticipant = chat.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      return chat.participantDetails[otherParticipant]?.name ?? 'Bilinmeyen Kullanıcı';
    }
    return chat.name;
  }

  String? _getChatPhotoUrl(ChatModel chat, String currentUserId) {
    if (chat.type == ChatType.private) {
      // Özel sohbet için diğer kullanıcının fotoğrafını bul
      final otherParticipant = chat.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      return chat.participantDetails[otherParticipant]?.photoUrl;
    }
    return chat.photoUrl;
  }

  Widget _buildMessagePreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İletilecek Mesaj:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: widget.message.senderPhotoUrl != null 
                    ? NetworkImage(widget.message.senderPhotoUrl!)
                    : null,
                child: widget.message.senderPhotoUrl == null
                    ? Text(
                        widget.message.senderName.isNotEmpty 
                            ? widget.message.senderName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.message.senderName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.message.text ?? 'Medya mesajı',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUser = authViewModel.user;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Kullanıcı bilgisi bulunamadı'),
        ),
      );
    }

    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Mesaj İlet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            _buildMessagePreview(),
            
            // Sohbet listesi
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ModernLoadingWidget(
                            size: 32,
                            color: Colors.white,
                            showMessage: false,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sohbetler yükleniyor...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  : _chats.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'İletilecek sohbet yok',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mesajı iletmek için başka sohbetleriniz olmalı',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Text(
                                    'Sohbet Seçin (${_chats.length})',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _chats.length,
                                itemBuilder: (context, index) {
                                  final chat = _chats[index];
                                  final displayName = _getChatDisplayName(chat, currentUser.uid);
                                  final photoUrl = _getChatPhotoUrl(chat, currentUser.uid);
                                  
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                                        backgroundImage: photoUrl != null 
                                            ? NetworkImage(photoUrl)
                                            : null,
                                        child: photoUrl == null
                                            ? Text(
                                                displayName.isNotEmpty 
                                                    ? displayName[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: chat.lastMessage != null
                                          ? Text(
                                              chat.lastMessage!.text ?? 'Medya mesajı',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : null,
                                      trailing: _isForwarding
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: ModernLoadingWidget(
                                                size: 20,
                                                color: Colors.white,
                                                showMessage: false,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.white70,
                                              size: 16,
                                            ),
                                      onTap: _isForwarding ? null : () => _forwardMessage(chat),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}



