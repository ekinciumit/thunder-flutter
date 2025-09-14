import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'private_chat_page.dart';
import 'message_search_page.dart';
import 'widgets/app_gradient_container.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatLastMessageTime(DateTime? lastMessageAt) {
    if (lastMessageAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dk önce';
    } else {
      return 'Şimdi';
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
            'Sohbetler',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessageSearchPage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<List<ChatModel>>(
          stream: _chatService.getUserChats(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Sohbetler yükleniyor...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hata: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              );
            }

            final chats = snapshot.data ?? [];
            
            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Henüz sohbet yok',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Etkinliklere katılarak yeni insanlarla tanışın!',
                      style: TextStyle(
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Ana sayfaya yönlendir
                        DefaultTabController.of(context).animateTo(0);
                      },
                      icon: const Icon(Icons.explore),
                      label: const Text('Etkinlikleri Keşfet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final displayName = _getChatDisplayName(chat, currentUser.uid);
                final photoUrl = _getChatPhotoUrl(chat, currentUser.uid);
                final unreadCount = chat.unreadCounts[currentUser.uid] ?? 0;
                final lastMessageTime = _formatLastMessageTime(chat.lastMessageAt);
                
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (chat.lastMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            chat.lastMessage!.text ?? 'Medya mesajı',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          lastMessageTime,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      if (chat.type == ChatType.private) {
                        final otherParticipant = chat.participants.firstWhere(
                          (id) => id != currentUser.uid,
                          orElse: () => '',
                        );
                        final otherParticipantName = chat.participantDetails[otherParticipant]?.name ?? 'Bilinmeyen';
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrivateChatPage(
                              currentUserId: currentUser.uid,
                              currentUserName: currentUser.displayName ?? 'Kullanıcı',
                              otherUserId: otherParticipant,
                              otherUserName: otherParticipantName,
                            ),
                          ),
                        );
                      }
                      // Grup sohbetleri için gelecekte eklenecek
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Yeni sohbet başlatma özelliği gelecekte eklenecek
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yeni sohbet özelliği yakında eklenecek')),
            );
          },
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }
}
