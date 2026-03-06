import '../../domain/repositories/chat_repository_interface.dart';
import '../../domain/entities/chat_entity.dart';

class GetMyChatsUseCase {
  final IChatRepository repository;
  GetMyChatsUseCase(this.repository);

  Stream<List<ChatEntity>> call(String uid) {
    return repository.getMyChats(uid);
  }
}
