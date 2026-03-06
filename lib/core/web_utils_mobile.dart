import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class WebUtils {
  static Future<XFile?> pickFile({String? accept}) async {
    FileType type = FileType.any;
    if (accept == 'audio/*') type = FileType.audio;
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: type);
    if (result != null) {
      final platformFile = result.files.single;
      return XFile(platformFile.path ?? '', bytes: platformFile.bytes, name: platformFile.name);
    }
    return null;
  }
}
