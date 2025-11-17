import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import 'cache_service.dart';

class ChatService {
  final _chatsRef = FirebaseFirestore.instance.collection('chats');
  final _messagesRef = FirebaseFirestore.instance.collection('messages');

  /// İki kullanıcı için benzersiz chatId üretir (sıralı)
  String getChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Özel sohbet oluştur veya getir
  Future<ChatModel> getOrCreatePrivateChat(String userA, String userB) async {
    final chatId = getChatId(userA, userB);
    final chatDoc = await _chatsRef.doc(chatId).get();
    
    if (chatDoc.exists) {
      final chatData = chatDoc.data()!;
      final chat = ChatModel.fromMap(chatData, chatDoc.id);
      
      // Eğer participantDetails eksikse, güncelle
      if (chat.participantDetails.isEmpty || 
          !chat.participantDetails.containsKey(userA) || 
          !chat.participantDetails.containsKey(userB)) {
        await _updateParticipantDetails(chatId, [userA, userB]);
        // Güncellenmiş chat'i tekrar al
        final updatedDoc = await _chatsRef.doc(chatId).get();
        return ChatModel.fromMap(updatedDoc.data()!, chatId);
      }
      
      return chat;
    } else {
      // Yeni özel sohbet oluştur
      final chat = ChatModel(
        id: chatId,
        name: 'Private Chat',
        type: ChatType.private,
        participants: [userA, userB],
        createdAt: DateTime.now(),
      );
      
      await _chatsRef.doc(chatId).set(chat.toMap());
      
      // ParticipantDetails'i doldur
      await _updateParticipantDetails(chatId, [userA, userB]);
      
      // Güncellenmiş chat'i döndür
      final updatedDoc = await _chatsRef.doc(chatId).get();
      return ChatModel.fromMap(updatedDoc.data()!, chatId);
    }
  }

  /// ParticipantDetails'i Firestore'dan kullanıcı bilgilerini çekerek güncelle
  Future<void> _updateParticipantDetails(String chatId, List<String> userIds) async {
    final participantDetailsMap = <String, ChatParticipant>{};
    
    for (final userId in userIds) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          participantDetailsMap[userId] = ChatParticipant(
            userId: userId,
            name: userData['displayName'] ?? 'Bilinmeyen Kullanıcı',
            photoUrl: userData['photoUrl'],
            joinedAt: DateTime.now(),
          );
        }
      } catch (e) {
        // Hata durumunda varsayılan değerler
        participantDetailsMap[userId] = ChatParticipant(
          userId: userId,
          name: 'Bilinmeyen Kullanıcı',
          joinedAt: DateTime.now(),
        );
    }
    }
    
    // Firestore'a kaydet
    final participantDetailsData = participantDetailsMap.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
    
    await _chatsRef.doc(chatId).update({
      'participantDetails': participantDetailsData,
    });
  }

  /// Grup sohbeti oluştur
  Future<ChatModel> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? description,
    String? photoUrl,
  }) async {
    final chatId = _chatsRef.doc().id;
    final chat = ChatModel(
      id: chatId,
      name: name,
      description: description,
      photoUrl: photoUrl,
      type: ChatType.group,
      participants: participants,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      admins: [createdBy],
    );
    
    await _chatsRef.doc(chatId).set(chat.toMap());
    return chat;
  }

  /// Mesaj gönder
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    String? text,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? gifUrl,
    String? stickerUrl,
    Map<String, dynamic>? location,
    Map<String, dynamic>? contact,
    String? replyToMessageId,
    String? forwardFromUserId,
    String? forwardFromUserName,
  }) async {
    // Debug: Sending message to chatId: $chatId, text: $text, type: $type
    final messageId = _messagesRef.doc().id;
    final message = MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: text,
      type: type,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      gifUrl: gifUrl,
      stickerUrl: stickerUrl,
      location: location,
      contact: contact,
      replyToMessageId: replyToMessageId,
      forwardFromUserId: forwardFromUserId,
      forwardFromUserName: forwardFromUserName,
    );

    try {
      // Mesajı kaydet
      // Debug: Saving message to Firestore...
      await _messagesRef.doc(messageId).set(message.toMap());
      // Debug: Message saved successfully
      
      // Chat'in son mesajını güncelle
      // Debug: Updating chat last message...
      await _chatsRef.doc(chatId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': message.toMap(),
      });
      // Debug: Chat updated successfully

      // Mesaj durumunu güncelle
      // Debug: Updating message status...
      await _messagesRef.doc(messageId).update({
        'status': MessageStatus.sent.name,
      });
      // Debug: Message status updated successfully

      return message.copyWith(status: MessageStatus.sent);
    } catch (e) {
      // Debug: Error sending message: $e
      rethrow;
    }
  }

  /// Mesajları dinle (stream) - Optimized version with pagination and caching
  Stream<List<MessageModel>> getMessagesStream(String chatId, {int limit = 50}) {
    return _messagesRef
        .where('chatId', isEqualTo: chatId)
        // orderBy kaldırıldı - index eksik olduğu için client-side sıralama yapıyoruz
        .snapshots()
        .handleError((error) {
          return <MessageModel>[]; // Hata durumunda boş liste döndür
        })
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <MessageModel>[];
      }
      
      final messages = snapshot.docs.map((doc) {
        try {
          final message = MessageModel.fromMap(doc.data(), doc.id);
          // Silinen mesajları filtrele
          if (message.isDeleted) {
            return null;
          }
          return message;
        } catch (e) {
          // Parse hatası olan mesajları atla
          return null;
        }
      }).whereType<MessageModel>().toList();
      
      // Client-side sıralama (timestamp'e göre - en eski üstte, en yeni altta)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Limit uygula (en son N mesaj)
      final limitedMessages = messages.length > limit 
          ? messages.sublist(messages.length - limit)
          : messages;
      
      // Cache'e kaydet (async olarak)
      CacheService.cacheMessages(chatId, limitedMessages);
      
      return limitedMessages;
    });
  }

  /// Daha eski mesajları yükle (pagination)
  Future<List<MessageModel>> loadOlderMessages(
    String chatId, 
    DateTime lastMessageTime, 
    {int limit = 20}
  ) async {
    try {
      final querySnapshot = await _messagesRef
          .where('chatId', isEqualTo: chatId)
          .limit(limit * 2) // Daha fazla al, sonra filtrele
          .get();

      final messages = querySnapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Timestamp'e göre filtrele ve sırala
      messages.removeWhere((msg) => msg.timestamp.isAfter(lastMessageTime));
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return messages.take(limit).toList();
    } catch (e) {
      // Debug: Error loading older messages: $e
      return [];
    }
  }

  /// Cache'den mesajları getir (offline support)
  Future<List<MessageModel>> getCachedMessages(String chatId) async {
    return await CacheService.getCachedMessages(chatId);
  }

  /// Mesajlarda arama yap
  Future<List<MessageModel>> searchMessages(
    String chatId, 
    String query, 
    {int limit = 50}
  ) async {
    try {
      final querySnapshot = await _messagesRef
          .where('chatId', isEqualTo: chatId)
          .limit(limit * 2) // Daha fazla al, sonra filtrele
          .get();

      final messages = querySnapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Text'e göre filtrele
      messages.removeWhere((msg) => 
        msg.text == null || !msg.text!.toLowerCase().contains(query.toLowerCase())
      );
      
      // Timestamp'e göre sıralama (en yeni mesajlar önce)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages.take(limit).toList();
    } catch (e) {
      // Debug: Error searching messages: $e
      return [];
    }
  }

  /// Tüm sohbetlerde arama yap
  Future<List<MessageModel>> searchAllMessages(
    String userId, 
    String query, 
    {int limit = 100}
  ) async {
    try {
      // Önce kullanıcının sohbetlerini al
      final chatsSnapshot = await _chatsRef
          .where('participants', arrayContains: userId)
          .get();

      final chatIds = chatsSnapshot.docs.map((doc) => doc.id).toList();
      
      if (chatIds.isEmpty) return [];

      // Her sohbet için arama yap
      final allResults = <MessageModel>[];
      for (final chatId in chatIds) {
        final messages = await searchMessages(chatId, query, limit: 20);
        allResults.addAll(messages);
      }

      // Timestamp'e göre sıralama ve limit uygula
      allResults.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allResults.take(limit).toList();
    } catch (e) {
      // Debug: Error searching all messages: $e
      return [];
    }
  }

  /// Mesaj ilet
  Future<MessageModel> forwardMessage({
    required MessageModel originalMessage,
    required String targetChatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  }) async {
    final messageId = _messagesRef.doc().id;
    final forwardedMessage = MessageModel(
      id: messageId,
      chatId: targetChatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: originalMessage.text,
      type: originalMessage.type,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      imageUrl: originalMessage.imageUrl,
      videoUrl: originalMessage.videoUrl,
      audioUrl: originalMessage.audioUrl,
      fileUrl: originalMessage.fileUrl,
      fileName: originalMessage.fileName,
      fileSize: originalMessage.fileSize,
      gifUrl: originalMessage.gifUrl,
      stickerUrl: originalMessage.stickerUrl,
      location: originalMessage.location,
      contact: originalMessage.contact,
      replyToMessageId: originalMessage.replyToMessageId,
      forwardFromUserId: originalMessage.senderId,
      forwardFromUserName: originalMessage.senderName,
      reactions: const {},
      isEdited: false,
      isDeleted: false,
      isPinned: false,
      metadata: {
        'isForwarded': true,
        'originalMessageId': originalMessage.id,
        'originalChatId': originalMessage.chatId,
        'forwardedAt': DateTime.now().toIso8601String(),
      },
    );

    try {
      // İletilen mesajı kaydet
      await _messagesRef.doc(messageId).set(forwardedMessage.toMap());
      
      // Chat'in son mesajını güncelle
      await _chatsRef.doc(targetChatId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': forwardedMessage.toMap(),
      });

      // Mesaj durumunu güncelle
      await _messagesRef.doc(messageId).update({
        'status': MessageStatus.sent.name,
      });

      return forwardedMessage.copyWith(status: MessageStatus.sent);
    } catch (e) {
      // Debug: Error forwarding message: $e
      rethrow;
    }
  }

  /// Kullanıcının sohbetlerini getir
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _chatsRef
        .where('participants', arrayContains: userId)
        .snapshots()
        .handleError((error) {
          // Hata durumunda boş liste döndür ve log'a yaz
          if (kDebugMode) {
            debugPrint('Chat listesi yükleme hatası: $error');
          }
          return <ChatModel>[];
        })
        .map((snapshot) {
      try {
        final chats = snapshot.docs.map((doc) {
          try {
            return ChatModel.fromMap(doc.data(), doc.id);
          } catch (e) {
            // Parse hatası olan chat'leri atla
            if (kDebugMode) {
              debugPrint('Chat parse hatası (${doc.id}): $e');
            }
            return null;
          }
        }).whereType<ChatModel>().toList();
        
        // Client-side sıralama (lastMessageAt'e göre)
        chats.sort((a, b) {
          if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
          if (a.lastMessageAt == null) return 1;
          if (b.lastMessageAt == null) return -1;
          return b.lastMessageAt!.compareTo(a.lastMessageAt!);
        });
        
        return chats;
      } catch (e) {
        // Genel hata durumunda boş liste döndür
        if (kDebugMode) {
          debugPrint('Chat listesi işleme hatası: $e');
        }
        return <ChatModel>[];
      }
    });
  }

  /// Mesaj durumunu güncelle
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    await _messagesRef.doc(messageId).update({
      'status': status.name,
      if (status == MessageStatus.read) 'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mesajı okundu olarak işaretle
  Future<void> markMessageAsRead(String messageId, String userId) async {
    await _messagesRef.doc(messageId).update({
      'status': MessageStatus.read.name,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Yazıyor durumunu güncelle
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    await _chatsRef.doc(chatId).update({
      'typingStatus.$userId': isTyping,
    });
  }

  /// Mesaja tepki ekle
  Future<void> addReaction(String messageId, String userId, String emoji) async {
    final messageDoc = await _messagesRef.doc(messageId).get();
    if (messageDoc.exists) {
      final data = messageDoc.data()!;
      final reactions = Map<String, List<String>>.from(data['reactions'] ?? {});
      
      if (reactions[userId] == null) {
        reactions[userId] = [];
      }
      
      if (!reactions[userId]!.contains(emoji)) {
        reactions[userId]!.add(emoji);
      }
      
      await _messagesRef.doc(messageId).update({
        'reactions': reactions,
      });
    }
  }

  /// Mesaj tepkisini kaldır
  Future<void> removeReaction(String messageId, String userId, String emoji) async {
    final messageDoc = await _messagesRef.doc(messageId).get();
    if (messageDoc.exists) {
      final data = messageDoc.data()!;
      final reactions = Map<String, List<String>>.from(data['reactions'] ?? {});
      
      if (reactions[userId] != null) {
        reactions[userId]!.remove(emoji);
        if (reactions[userId]!.isEmpty) {
          reactions.remove(userId);
        }
      }
      
      await _messagesRef.doc(messageId).update({
        'reactions': reactions,
      });
    }
  }

  /// Mesajı sil
  Future<void> deleteMessage(String messageId, String userId) async {
    await _messagesRef.doc(messageId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mesajı düzenle
  Future<void> editMessage(String messageId, String newText) async {
    await _messagesRef.doc(messageId).update({
      'text': newText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mesajı sabitle
  Future<void> pinMessage(String messageId, String chatId) async {
    await _messagesRef.doc(messageId).update({
      'isPinned': true,
      'pinnedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mesajı sabitleme kaldır
  Future<void> unpinMessage(String messageId) async {
    await _messagesRef.doc(messageId).update({
      'isPinned': false,
      'pinnedAt': null,
    });
  }

  /// Okunmamış mesaj sayısını güncelle
  Future<void> updateUnreadCount(String chatId, String userId, int count) async {
    await _chatsRef.doc(chatId).update({
      'unreadCounts.$userId': count,
    });
  }

  /// Son görülme zamanını güncelle
  Future<void> updateLastSeen(String chatId, String userId) async {
    await _chatsRef.doc(chatId).update({
      'lastSeen.$userId': FieldValue.serverTimestamp(),
    });
  }

  /// Sesli mesaj gönder
  Future<MessageModel> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String audioUrl,
    required Duration duration,
  }) async {
    final messageData = {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': null,
      'type': MessageType.audio.name,
      'status': MessageStatus.sending.name,
      'timestamp': FieldValue.serverTimestamp(),
      'audioUrl': audioUrl,
      'metadata': {
        'duration': duration.inMilliseconds,
        'audioFormat': 'm4a',
      },
      'reactions': {},
      'isEdited': false,
      'isDeleted': false,
      'isPinned': false,
    };

    final docRef = await _messagesRef.add(messageData);
    
    // Chat'i güncelle
    await _updateChatLastMessage(chatId, 'Sesli mesaj', MessageType.audio);
    
    return MessageModel.fromMap({
      ...messageData,
      'id': docRef.id,
      'timestamp': DateTime.now(),
    }, docRef.id);
  }

  /// Chat'in son mesajını güncelle
  Future<void> _updateChatLastMessage(String chatId, String lastMessage, MessageType messageType) async {
    await _chatsRef.doc(chatId).update({
      'lastMessage': lastMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageType': messageType.name,
    });
  }

  /// Dosya mesajı gönder
  Future<MessageModel> sendFileMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    String? fileExtension,
  }) async {
    final messageData = {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': null,
      'type': MessageType.file.name,
      'status': MessageStatus.sending.name,
      'timestamp': FieldValue.serverTimestamp(),
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'metadata': {
        'fileExtension': fileExtension,
        'uploadedAt': FieldValue.serverTimestamp(),
      },
      'reactions': {},
      'isEdited': false,
      'isDeleted': false,
      'isPinned': false,
    };

    final docRef = await _messagesRef.add(messageData);
    
    // Chat'i güncelle
    await _updateChatLastMessage(chatId, 'Dosya: $fileName', MessageType.file);
    
    return MessageModel.fromMap({
      ...messageData,
      'id': docRef.id,
      'timestamp': DateTime.now(),
    }, docRef.id);
  }
} 