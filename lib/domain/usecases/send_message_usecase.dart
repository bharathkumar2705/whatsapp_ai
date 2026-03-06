import '../../domain/repositories/chat_repository_interface.dart';
import '../../domain/entities/message_entity.dart';

class SendMessageUseCase {
  final IChatRepository repository;
  SendMessageUseCase(this.repository);

  Future<void> call(MessageEntity message) async {
    return await repository.sendMessage(message);
  }
}
