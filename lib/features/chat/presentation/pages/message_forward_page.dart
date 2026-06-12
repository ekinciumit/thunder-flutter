import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../../../../core/widgets/app_gradient_container.dart';
import '../../../../core/widgets/modern_loading_widget.dart';
import '../../../../l10n/app_localizations.dart';

class MessageForwardPage extends StatefulWidget {
  final MessageEntity message;

  const MessageForwardPage({
    super.key,
    required this.message,
  });

  @override
  State<MessageForwardPage> createState() => _MessageForwardPageState();
}

class _MessageForwardPageState extends State<MessageForwardPage> {
  List<ChatEntity> _chats = [];
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatsLoadError(e.toString()))),
        );
      }
    }
  }

  Future<void> _forwardMessage(ChatEntity targetChat) async {
    setState(() {
      _isForwarding = true;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final currentUser = authViewModel.user;
      
      if (currentUser == null) return;

      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      // ViewModel zaten Entity bekliyor
      await chatViewModel.forwardMessage(
        originalMessage: widget.message,
        targetChatId: targetChat.id,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? AppLocalizations.of(context)!.user,
        senderPhotoUrl: currentUser.photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.messageForwardedSuccess)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.messageForwardFailed(e.toString()))),
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

  String _getChatDisplayName(ChatEntity chat, String currentUserId) {
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

  String? _getChatPhotoUrl(ChatEntity chat, String currentUserId) {
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

  Widget _buildMessagePreview(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? theme.colorScheme.outline.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İletilecek Mesaj:',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark 
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.primaryContainer,
                backgroundImage: widget.message.senderPhotoUrl != null 
                    ? NetworkImage(widget.message.senderPhotoUrl!)
                    : null,
                child: widget.message.senderPhotoUrl == null
                    ? Text(
                        widget.message.senderName.isNotEmpty 
                            ? widget.message.senderName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
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
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.message.text ?? 'Medya mesajı',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Kullanıcı bilgisi bulunamadı',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
      );
    }

    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Mesaj İlet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.colorScheme.onSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            _buildMessagePreview(context),
            
            // Sohbet listesi
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ModernLoadingWidget(
                            size: 32,
                            color: theme.colorScheme.primary,
                            showMessage: false,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sohbetler yükleniyor...',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'İletilecek sohbet yok',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mesajı iletmek için başka sohbetleriniz olmalı',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
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
                                      color: theme.colorScheme.onSurfaceVariant,
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
                                      color: isDark 
                                          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                                          : theme.colorScheme.surface.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark 
                                            ? theme.colorScheme.outline.withValues(alpha: 0.3)
                                            : theme.colorScheme.outline.withValues(alpha: 0.2),
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
                                        backgroundColor: theme.colorScheme.primaryContainer,
                                        backgroundImage: photoUrl != null 
                                            ? NetworkImage(photoUrl)
                                            : null,
                                        child: photoUrl == null
                                            ? Text(
                                                displayName.isNotEmpty 
                                                    ? displayName[0].toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.onPrimaryContainer,
                                                ),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        displayName,
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: chat.lastMessage != null
                                          ? Text(
                                              chat.lastMessage!.text ?? 'Medya mesajı',
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurfaceVariant,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : null,
                                      trailing: _isForwarding
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: ModernLoadingWidget(
                                                size: 20,
                                                color: theme.colorScheme.primary,
                                                showMessage: false,
                                              ),
                                            )
                                          : Icon(
                                              Icons.arrow_forward_ios,
                                              color: theme.colorScheme.onSurfaceVariant,
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



