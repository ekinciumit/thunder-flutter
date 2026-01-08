import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../services/cache_service.dart';
import '../../../../core/utils/image_compressor.dart';

/// Chat Remote Data Source Interface
/// 
/// Clean Architecture Data Layer
/// Firebase işlemleri için abstract interface.
abstract class ChatRemoteDataSource {
  String getChatId(String userA, String userB);
  Future<ChatModel?> getChatById(String chatId);
  Future<ChatModel> getOrCreatePrivateChat(String userA, String userB);
  Future<ChatModel> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? description,
    String? photoUrl,
  });
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
  });
  Stream<List<MessageModel>> getMessagesStream(String chatId, {int limit = 50});
  Future<List<MessageModel>> loadOlderMessages(String chatId, DateTime lastMessageTime, {int limit = 20});
  Stream<List<ChatModel>> getUserChats(String userId);
  Future<void> markMessageAsRead(String messageId, String userId);
  Future<void> deleteMessage(String messageId, String userId);
  Future<void> editMessage(String messageId, String newText);
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping);
  Future<void> addReaction(String messageId, String userId, String emoji);
  Future<void> removeReaction(String messageId, String userId, String emoji);
  Future<MessageModel> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String audioUrl,
    required Duration duration,
  });
  Future<MessageModel> sendFileMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    String? fileExtension,
  });
  Future<MessageModel> forwardMessage({
    required MessageModel originalMessage,
    required String targetChatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  });
  Future<List<MessageModel>> searchMessages(String chatId, String query, {int limit = 50});
  Future<List<MessageModel>> searchAllMessages(String userId, String query, {int limit = 100});
  
  /// Ses dosyasını Firebase Storage'a yükler ve download URL'ini döndürür
  Future<String> uploadVoiceMessage(File audioFile, {required String chatId, required String senderId});
  
  /// Dosyayı Firebase Storage'a yükler ve download URL'ini döndürür
  Future<String> uploadFileMessage(File file, String fileName, {required String chatId, required String senderId});
  
  /// Chat medya (image/video) dosyasını Firebase Storage'a yükler
  /// Progress callback ile progress güncellemesi yapılabilir
  Future<String> uploadChatMedia(File file, String storagePath, {String? contentType, void Function(double progress)? onProgress});
}

/// Chat Remote Data Source Implementation
/// 
/// Clean Architecture Data Layer
/// Firebase Firestore işlemlerini yapar.
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final CollectionReference<Map<String, dynamic>> _chatsRef;
  final CollectionReference<Map<String, dynamic>> _messagesRef;

  ChatRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _chatsRef = (firestore ?? FirebaseFirestore.instance).collection('chats'),
        _messagesRef = (firestore ?? FirebaseFirestore.instance).collection('messages');

  @override
  String getChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final chatDoc = await _chatsRef.doc(chatId).get();
      if (!chatDoc.exists) return null;
      return ChatModel.fromMap(chatDoc.data()!, chatId);
    } catch (e) {
      throw ServerException('Chat getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<ChatModel> getOrCreatePrivateChat(String userA, String userB) async {
    try {
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
    } catch (e) {
      throw ServerException('Özel sohbet oluşturulurken hata oluştu: ${e.toString()}');
    }
  }

  Future<void> _updateParticipantDetails(String chatId, List<String> userIds) async {
    final participantDetailsMap = <String, ChatParticipant>{};

    for (final userId in userIds) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
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

  @override
  Future<ChatModel> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? description,
    String? photoUrl,
  }) async {
    try {
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
    } catch (e) {
      throw ServerException('Grup sohbeti oluşturulurken hata oluştu: ${e.toString()}');
    }
  }

  @override
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
  }) async {
    try {
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
      );

      // Mesajı kaydet
      await _messagesRef.doc(messageId).set(message.toMap());

      // Chat'in son mesajını güncelle
      await _chatsRef.doc(chatId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': message.toMap(),
      });

      // Mesaj durumunu güncelle
      await _messagesRef.doc(messageId).update({
        'status': MessageStatus.sent.name,
      });

      return message.copyWith(status: MessageStatus.sent);
    } catch (e) {
      throw ServerException('Mesaj gönderilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId, {int limit = 50}) {
    try {
      // Performance: Server-side orderBy + limit (Firestore maliyetini düşürür)
      // En yeni mesajları al (descending: true), UI'da ters çevireceğiz
      return _messagesRef
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true) // ✅ Server-side sorting
          .limit(limit) // ✅ Server-side limit
          .snapshots()
          .handleError((error) {
            if (kDebugMode) {
              debugPrint('❌ [CHAT_DS] getMessagesStream error: $error');
            }
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
            if (kDebugMode) {
              debugPrint('⚠️ [CHAT_DS] Message parse error: $e');
            }
            return null;
          }
        }).whereType<MessageModel>().toList();

        // Server'dan en yeni mesajlar geldi (descending: true)
        // UI'da en eski üstte gösterilmeli, bu yüzden ters çevir
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Cache'e kaydet (async olarak)
        CacheService.cacheMessages(chatId, messages);

        return messages;
      });
    } catch (e) {
      throw ServerException('Mesajlar getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<List<MessageModel>> loadOlderMessages(
      String chatId, DateTime lastMessageTime,
      {int limit = 20}) async {
    try {
      // Performance: Server-side pagination (endBefore ile)
      // En eski mesajları al (ascending: true, lastMessageTime'dan önceki)
      // NOT: Index gerekiyor: chatId (ASC) + timestamp (ASC)
      final querySnapshot = await _messagesRef
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: false) // En eski üstte
          .endBefore([Timestamp.fromDate(lastMessageTime)]) // lastMessageTime'dan önceki mesajlar
          .limit(limit) // ✅ Server-side limit
          .get();

      final messages = querySnapshot.docs.map((doc) {
        try {
          final message = MessageModel.fromMap(doc.data(), doc.id);
          // Silinen mesajları filtrele
          if (message.isDeleted) {
            return null;
          }
          return message;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [CHAT_DS] loadOlderMessages parse error: $e');
          }
          return null;
        }
      }).whereType<MessageModel>().toList();

      // Server'dan zaten ascending sırada geldi (en eski üstte)
      // UI'da da aynı sırada gösterilmeli, sıralama gerekmez
      return messages;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [CHAT_DS] loadOlderMessages error: $e');
      }
      throw ServerException('Eski mesajlar yüklenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Stream<List<ChatModel>> getUserChats(String userId) {
    try {
      return _chatsRef
          .where('participants', arrayContains: userId)
          .snapshots()
          .handleError((error) {
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
    } catch (e) {
      throw ServerException('Kullanıcı sohbetleri getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      await _messagesRef.doc(messageId).update({
        'status': MessageStatus.read.name,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Mesaj okundu olarak işaretlenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      await _messagesRef.doc(messageId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Mesaj silinirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> editMessage(String messageId, String newText) async {
    try {
      await _messagesRef.doc(messageId).update({
        'text': newText,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Mesaj düzenlenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      await _chatsRef.doc(chatId).update({
        'typingStatus.$userId': isTyping,
      });
    } catch (e) {
      throw ServerException('Yazıyor durumu güncellenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> addReaction(String messageId, String userId, String emoji) async {
    try {
      final messageDoc = await _messagesRef.doc(messageId).get();
      if (messageDoc.exists) {
        final data = messageDoc.data()!;
        final reactionsData = data['reactions'] ?? {};
        final reactions = <String, List<String>>{};
        
        // Safely convert reactions map
        if (reactionsData is Map) {
          reactionsData.forEach((key, value) {
            if (value is List) {
              reactions[key.toString()] = value.map((e) => e.toString()).toList();
            }
          });
        }
        
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
    } catch (e) {
      throw ServerException('Tepki eklenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> removeReaction(String messageId, String userId, String emoji) async {
    try {
      final messageDoc = await _messagesRef.doc(messageId).get();
      if (messageDoc.exists) {
        final data = messageDoc.data()!;
        final reactionsData = data['reactions'] ?? {};
        final reactions = <String, List<String>>{};
        
        // Safely convert reactions map
        if (reactionsData is Map) {
          reactionsData.forEach((key, value) {
            if (value is List) {
              reactions[key.toString()] = value.map((e) => e.toString()).toList();
            }
          });
        }
        
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
    } catch (e) {
      throw ServerException('Tepki kaldırılırken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<MessageModel> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String audioUrl,
    required Duration duration,
  }) async {
    try {
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
      await _chatsRef.doc(chatId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': {
          ...messageData,
          'id': docRef.id,
          'timestamp': Timestamp.fromDate(DateTime.now()),
        },
      });
      
      // Mesaj durumunu güncelle
      await _messagesRef.doc(docRef.id).update({
        'status': MessageStatus.sent.name,
      });
      
      return MessageModel.fromMap({
        ...messageData,
        'id': docRef.id,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'status': MessageStatus.sent.name,
      }, docRef.id);
    } catch (e) {
      throw ServerException('Sesli mesaj gönderilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
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
    try {
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
      await _chatsRef.doc(chatId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': {
          ...messageData,
          'id': docRef.id,
          'timestamp': Timestamp.fromDate(DateTime.now()),
        },
      });
      
      // Mesaj durumunu güncelle
      await _messagesRef.doc(docRef.id).update({
        'status': MessageStatus.sent.name,
      });
      
      return MessageModel.fromMap({
        ...messageData,
        'id': docRef.id,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'status': MessageStatus.sent.name,
      }, docRef.id);
    } catch (e) {
      throw ServerException('Dosya mesajı gönderilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<MessageModel> forwardMessage({
    required MessageModel originalMessage,
    required String targetChatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  }) async {
    try {
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
      throw ServerException('Mesaj iletilemedi: ${e.toString()}');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages(String chatId, String query, {int limit = 50}) async {
    try {
      // Cost Optimization: Use server-side orderBy + reasonable limit
      // Note: Firestore doesn't support full-text search, so we still need client-side filtering
      // But we limit the initial fetch to reduce read costs
      final querySnapshot = await _messagesRef
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true) // ✅ Server-side sorting
          .limit(limit * 3) // Fetch 3x limit to account for filtering (reduced from unlimited)
          .get();

      final messages = querySnapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Client-side text filtering (Firestore doesn't support contains)
      final queryLower = query.toLowerCase();
      messages.removeWhere((msg) => 
        msg.text == null || !msg.text!.toLowerCase().contains(queryLower)
      );
      
      // Already sorted by timestamp (descending) from server
      return messages.take(limit).toList();
    } catch (e) {
      throw ServerException('Mesajlar aranırken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<List<MessageModel>> searchAllMessages(String userId, String query, {int limit = 100}) async {
    try {
      // Cost Optimization: Optimized N-query method (instead of N+1)
      // Step 1: Get user's chat IDs (single query)
      final chatsSnapshot = await _chatsRef
          .where('participants', arrayContains: userId)
          .get();

      final chatIds = chatsSnapshot.docs.map((doc) => doc.id).toList();
      
      if (chatIds.isEmpty) return [];

      // Step 2: Search in each chat using optimized searchMessages (server-side orderBy + limit)
      // searchMessages already uses server-side orderBy and limit, reducing read costs
      final allResults = <MessageModel>[];
      for (final chatId in chatIds) {
        final messages = await searchMessages(chatId, query, limit: 20); // Each chat: max 20 results
        allResults.addAll(messages);
      }

      // Step 3: Sort all results by timestamp (descending) and return top N
      allResults.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allResults.take(limit).toList();
    } catch (e) {
      throw ServerException('Tüm mesajlar aranırken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadVoiceMessage(File audioFile, {required String chatId, required String senderId}) async {
    try {
      // Dosya kontrolü
      if (!await audioFile.exists()) {
        throw ServerException('Ses dosyası bulunamadı');
      }

      // Güvenlik: chatId ve senderId bazlı path yapısı
      final fileId = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storageRef = _storage
          .ref()
          .child('voice_messages')
          .child(chatId)
          .child(senderId)
          .child(fileId);

      // Dosyayı yükle
      final uploadTask = storageRef.putFile(audioFile);
      
      // Upload tamamlanana kadar bekle
      final snapshot = await uploadTask;
      
      // Download URL'ini al
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Ses dosyası yüklenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadFileMessage(File file, String fileName, {required String chatId, required String senderId}) async {
    try {
      // Dosya kontrolü
      if (!await file.exists()) {
        throw ServerException('Dosya bulunamadı');
      }

      // Güvenlik: chatId ve senderId bazlı path yapısı
      final fileId = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storageRef = _storage
          .ref()
          .child('chat_files')
          .child(chatId)
          .child(senderId)
          .child(fileId);

      // Dosyayı yükle
      final uploadTask = storageRef.putFile(file);
      
      // Upload tamamlanana kadar bekle
      final snapshot = await uploadTask;
      
      // Download URL'ini al
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Dosya yüklenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadChatMedia(File file, String storagePath, {String? contentType, void Function(double progress)? onProgress}) async {
    try {
      // Dosya kontrolü
      if (!await file.exists()) {
        throw ServerException('Medya dosyası bulunamadı');
      }

      // Cost Optimization: Compress image before upload (only for images, not videos)
      File fileToUpload = file;
      final isImage = contentType == null || 
                      contentType.startsWith('image/') ||
                      (!file.path.endsWith('.mp4') && !file.path.endsWith('.mov') && !file.path.endsWith('.m4a'));
      
      if (isImage) {
        try {
          fileToUpload = await ImageCompressor.compressChatMedia(file);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [CHAT_DS] Image compression failed, using original: $e');
          }
          // If compression fails, use original file
          fileToUpload = file;
        }
      }

      // Firebase Storage path'i oluştur
      final storageRef = _storage.ref().child(storagePath);

      // Metadata oluştur
      final metadata = SettableMetadata(
        contentType: contentType ?? (file.path.endsWith('.mp4') || file.path.endsWith('.mov') ? 'video/mp4' : 'image/jpeg'),
      );

      // Dosyayı yükle (byte data olarak)
      final fileBytes = await fileToUpload.readAsBytes();
      final uploadTask = storageRef.putData(fileBytes, metadata);
      
      // Progress dinle (eğer callback verildiyse)
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      // Upload tamamlanana kadar bekle
      final snapshot = await uploadTask;
      
      // Download URL'ini al
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up temporary compressed file
      try {
        if (fileToUpload.path != file.path) {
          await fileToUpload.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
      
      return downloadUrl;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Medya dosyası yüklenirken hata oluştu: ${e.toString()}');
    }
  }
}

