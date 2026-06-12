import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../entities/message_entity.dart';

/// Chat Repository Interface
/// 
/// Clean Architecture Domain Layer
/// Bu interface chat işlemleri için abstract tanımlar içerir.
abstract class ChatRepository {
  /// İki kullanıcı için benzersiz chatId üretir
  String getChatId(String userA, String userB);
  
  /// Chat'i ID'ye göre getir
  Future<Either<Failure, ChatEntity?>> getChatById(String chatId);
  
  /// Chat'i stream olarak getir
  Stream<ChatEntity?> getChatStream(String chatId);
  
  /// Özel sohbet oluştur veya getir
  Future<Either<Failure, ChatEntity>> getOrCreatePrivateChat(String userA, String userB);
  
  /// Grup sohbeti oluştur
  Future<Either<Failure, ChatEntity>> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? description,
    String? photoUrl,
  });
  
  /// Mesaj gönder
  Future<Either<Failure, MessageEntity>> sendMessage({
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
  Stream<List<MessageEntity>> getMessagesStream(String chatId, {int limit = 50});
  
  /// Daha eski mesajları yükle (pagination)
  Future<Either<Failure, List<MessageEntity>>> loadOlderMessages(
    String chatId,
    DateTime lastMessageTime, {
    int limit = 20,
  });
  
  /// Kullanıcının sohbetlerini getir
  Stream<List<ChatEntity>> getUserChats(String userId);
  
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
  Future<Either<Failure, MessageEntity>> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String audioUrl,
    required Duration duration,
  });
  
  /// Dosya mesajı gönder
  Future<Either<Failure, MessageEntity>> sendFileMessage({
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
  Future<Either<Failure, MessageEntity>> forwardMessage({
    required MessageEntity originalMessage,
    required String targetChatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  });
  
  /// Mesajlarda arama yap
  Future<Either<Failure, List<MessageEntity>>> searchMessages(
    String chatId,
    String query, {
    int limit = 50,
  });
  
  /// Tüm sohbetlerde arama yap
  Future<Either<Failure, List<MessageEntity>>> searchAllMessages(
    String userId,
    String query, {
    int limit = 100,
  });
  
  /// Ses dosyasını Firebase Storage'a yükler ve download URL'ini döndürür
  Future<Either<Failure, String>> uploadVoiceMessage(String audioFilePath, {required String chatId, required String senderId});
  
  /// Dosyayı Firebase Storage'a yükler ve download URL'ini döndürür
  Future<Either<Failure, String>> uploadFileMessage(String filePath, String fileName, {required String chatId, required String senderId});
  
  /// Chat medya (image/video) dosyasını Firebase Storage'a yükler
  /// Progress callback ile progress güncellemesi yapılabilir
  Future<Either<Failure, String>> uploadChatMedia(String filePath, String storagePath, {String? contentType, void Function(double progress)? onProgress});
  
  /// Grup bilgilerini güncelle (sadece yöneticiler)
  Future<Either<Failure, void>> updateGroupInfo({
    required String chatId,
    String? name,
    String? description,
    String? photoUrl,
  });
  
  /// Kullanıcıyı yönetici yap (sadece yöneticiler)
  Future<Either<Failure, void>> addAdmin({
    required String chatId,
    required String userId,
  });
  
  /// Kullanıcıyı yöneticilikten çıkar (sadece yöneticiler)
  Future<Either<Failure, void>> removeAdmin({
    required String chatId,
    required String userId,
  });

  /// Gruba üye ekle (sadece yöneticiler)
  Future<Either<Failure, void>> addGroupParticipants({
    required String chatId,
    required List<String> userIds,
  });

  /// Gruptan üye çıkar
  Future<Either<Failure, void>> removeGroupParticipant({
    required String chatId,
    required String userId,
  });

  /// Sohbeti sessize al
  Future<Either<Failure, void>> muteChat({
    required String chatId,
    required String userId,
    DateTime? muteUntil,
  });

  /// Sohbet sessize almayı kaldır
  Future<Either<Failure, void>> unmuteChat({
    required String chatId,
    required String userId,
  });
}

