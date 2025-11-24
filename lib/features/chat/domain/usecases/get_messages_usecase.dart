import '../../../../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// Get Messages Use Case
/// 
/// Clean Architecture Domain Layer
/// Mesajları stream olarak getirme iş kuralını içerir.
class GetMessagesUseCase {
  final ChatRepository _repository;

  GetMessagesUseCase(this._repository);

  /// Mesajları stream olarak getir
  /// 
  /// Returns: Stream<List<MessageModel>>
  Stream<List<MessageModel>> call(String chatId, {int limit = 50}) {
    return _repository.getMessagesStream(chatId, limit: limit);
  }
}

