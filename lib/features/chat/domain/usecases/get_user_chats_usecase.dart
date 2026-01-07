import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

/// Get User Chats Use Case
/// 
/// Clean Architecture Domain Layer
/// Kullanıcının sohbetlerini getirme iş kuralını içerir.
class GetUserChatsUseCase {
  final ChatRepository _repository;

  GetUserChatsUseCase(this._repository);

  /// Kullanıcının sohbetlerini getir
  /// 
  /// Returns: ``Stream<List<ChatEntity>>``
  Stream<List<ChatEntity>> call(String userId) {
    return _repository.getUserChats(userId);
  }
}

