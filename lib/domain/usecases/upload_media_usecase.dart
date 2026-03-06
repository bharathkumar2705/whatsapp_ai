import 'package:image_picker/image_picker.dart';
import '../../data/repositories/storage_repository.dart';

class UploadMediaUseCase {
  final StorageRepository repository;
  UploadMediaUseCase(this.repository);

  Future<String> call(XFile file, String chatId) async {
    return await repository.uploadMessageMedia(file, chatId);
  }
}
