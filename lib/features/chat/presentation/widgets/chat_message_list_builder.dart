import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../../domain/entities/message_entity.dart';
import 'message_list.dart';
import '../../../../core/widgets/skeleton_widgets.dart';

/// Widget that builds the message list with Selector for performance optimization
class ChatMessageListBuilder extends StatefulWidget {
  final String? chatId;
  final String currentUserId;
  final String currentUserName;
  final ScrollController scrollController;
  final bool isLoadingOlderMessages;
  final String Function(MessageEntity) getDisplayName;
  final String Function(DateTime) formatMessageTime;
  final void Function(MessageEntity) onLongPress;
  final void Function(MessageEntity, String) onReactionTap;
  final VoidCallback onScrollToBottom;
  final void Function(List<MessageEntity>) onMessagesUpdated;

  const ChatMessageListBuilder({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.currentUserName,
    required this.scrollController,
    required this.isLoadingOlderMessages,
    required this.getDisplayName,
    required this.formatMessageTime,
    required this.onLongPress,
    required this.onReactionTap,
    required this.onScrollToBottom,
    required this.onMessagesUpdated,
  });

  @override
  State<ChatMessageListBuilder> createState() => _ChatMessageListBuilderState();
}

class _ChatMessageListBuilderState extends State<ChatMessageListBuilder> {
  bool _isInitialLoad = true;
  Set<String> _previousMessageIds = {}; // Sadece ID'leri sakla, mesajları değil

  @override
  void initState() {
    super.initState();
    // Timeout: 3 saniye sonra loading'i kapat (mesaj gelmese bile)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isInitialLoad) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // chatId yoksa skeleton göster
    if (widget.chatId == null) {
      return const MessageListSkeleton();
    }

    if (_isInitialLoad) {
      return const MessageListSkeleton();
    }

    return Selector<ChatViewModel, List<MessageEntity>>(
      selector: (_, vm) => widget.chatId != null ? vm.getMessagesForChat(widget.chatId!) : <MessageEntity>[],
      shouldRebuild: (previous, next) {
        // Performance: Sadece mesaj listesi değiştiyse rebuild
        if (previous.length != next.length) return true;
        if (previous.map((e) => e.id).toSet() != next.map((e) => e.id).toSet()) return true;
        // İçerik değişikliği kontrolü
        final prevMap = {for (var m in previous) m.id: m};
        return next.any((msg) {
          final oldMsg = prevMap[msg.id];
          if (oldMsg == null) return true;
          return oldMsg.text != msg.text ||
              oldMsg.reactions.toString() != msg.reactions.toString() ||
              oldMsg.isEdited != msg.isEdited ||
              oldMsg.isDeleted != msg.isDeleted;
        });
      },
      builder: (context, messageEntities, _) {
        // Entity'leri direkt kullan (Clean Architecture: UI Entity görmeli)
        final sortedMessages = List<MessageEntity>.from(messageEntities);
        sortedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // İlk yükleme tamamlandı mı kontrol et (sadece bir kez)
        if (_isInitialLoad && sortedMessages.isNotEmpty) {
          // Sadece bir kez setState yap ve scroll yap
          Future.microtask(() {
            if (mounted && _isInitialLoad) {
              setState(() {
                _isInitialLoad = false;
              });
              
              // İlk yüklemede son mesajlara scroll yap (WhatsApp gibi)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (widget.scrollController.hasClients && sortedMessages.isNotEmpty) {
                    widget.scrollController.jumpTo(
                      widget.scrollController.position.maxScrollExtent,
                    );
                  }
                });
              });
            }
          });
        }
        
        // Yeni mesajlar var mı kontrol et (scroll için)
        final currentIds = sortedMessages.map((m) => m.id).toSet();
        final newMessages = sortedMessages.where((m) => !_previousMessageIds.contains(m.id)).toList();
        
        // State'i güncelle (scroll kontrolü için) - sadece gerçekten değiştiyse
        // BU ÇOK ÖNEMLİ: builder içinde setState çağırmayın, sadece callback çağırın
        if (currentIds != _previousMessageIds) {
          // ID'leri güncelle (setState olmadan, sadece state değişkenini güncelle)
          _previousMessageIds = currentIds;
          
          // onMessagesUpdated callback'ini sadece gerçekten değişiklik varsa çağır
          // Future.microtask kullan ki builder içinde setState çağrılmasın
          Future.microtask(() {
            widget.onMessagesUpdated(messageEntities);
            
            // Yeni mesaj geldiğinde scroll yap (sadece yeni mesaj varsa)
            if (newMessages.isNotEmpty) {
              widget.onScrollToBottom();
            }
          });
        }
        
        return MessageList(
          key: ValueKey('messages_${sortedMessages.length}'), // Daha basit key
          messages: sortedMessages,
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
          scrollController: widget.scrollController,
          isLoadingOlderMessages: widget.isLoadingOlderMessages,
          getDisplayName: widget.getDisplayName,
          formatMessageTime: widget.formatMessageTime,
          onLongPress: widget.onLongPress,
          onReactionTap: widget.onReactionTap,
        );
      },
    );
  }
}

