import '../../../../core/errors/failures.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/message_model.dart';

/// Chat Repository Interface
/// 
/// Clean Architecture Domain Layer
/// Bu interface chat işlemleri için abstract tanımlar içerir.
abstract class ChatRepository {
  /// İki kullanıcı için benzersiz chatId üretir
  String getChatId(String userA, String userB);
  
  /// Özel sohbet oluştur veya getir
  Future<Either<Failure, ChatModel>> getOrCreatePrivateChat(String userA, String userB);
  
  /// Grup sohbeti oluştur
  Future<Either<Failure, ChatModel>> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? description,
    String? photoUrl,
  });
  
  /// Mesaj gönder
  Future<Either<Failure, MessageModel>> sendMessage({
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
  
  /// Mesajları stream olarak getir
  Stream<List<MessageModel>> getMessagesStream(String chatId, {int limit = 50});
  
  /// Daha eski mesajları yükle (pagination)
  Future<Either<Failure, List<MessageModel>>> loadOlderMessages(
    String chatId,
    DateTime lastMessageTime, {
    int limit = 20,
  });
  
  /// Kullanıcının sohbetlerini getir
  Stream<List<ChatModel>> getUserChats(String userId);
  
  /// Mesajı okundu olarak işaretle
  Future<Either<Failure, void>> markMessageAsRead(String messageId, String userId);
  
  /// Mesajı sil
  Future<Either<Failure, void>> deleteMessage(String messageId, String userId);
  
  /// Mesajı düzenle
  Future<Either<Failure, void>> editMessage(String messageId, String newText);
  
  /// Yazıyor durumunu güncelle
  Future<Either<Failure, void>> updateTypingStatus(String chatId, String userId, bool isTyping);
  
  /// Mesaja tepki ekle
  Future<Either<Failure, void>> addReaction(String messageId, String userId, String emoji);
  
  /// Mesaj tepkisini kaldır
  Future<Either<Failure, void>> removeReaction(String messageId, String userId, String emoji);
  
  /// Sesli mesaj gönder
  Future<Either<Failure, MessageModel>> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String audioUrl,
    required Duration duration,
  });
  
  /// Dosya mesajı gönder
  Future<Either<Failure, MessageModel>> sendFileMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    String? fileExtension,
  });
  
  /// Mesaj ilet
  Future<Either<Failure, MessageModel>> forwardMessage({
    required MessageModel originalMessage,
    required String targetChatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  });
  
  /// Mesajlarda arama yap
  Future<Either<Failure, List<MessageModel>>> searchMessages(
    String chatId,
    String query, {
    int limit = 50,
  });
  
  /// Tüm sohbetlerde arama yap
  Future<Either<Failure, List<MessageModel>>> searchAllMessages(
    String userId,
    String query, {
    int limit = 100,
  });
}

