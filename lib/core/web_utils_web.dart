import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class WebUtils {
  static Future<XFile?> pickFile({String? accept}) async {
    final completer = Completer<XFile?>();
    final input = html.FileUploadInputElement();
    if (accept != null) input.accept = accept;
    
    input.onChange.listen((event) {
      if (input.files!.isEmpty) {
        completer.complete(null);
        return;
      }
      final file = input.files![0];
      final reader = html.FileReader();
      
      reader.onLoadEnd.listen((e) {
        final result = reader.result as List<int>;
        completer.complete(XFile.fromData(
          Uint8List.fromList(result),
          name: file.name,
          mimeType: file.type,
        ));
      });
      
      reader.readAsArrayBuffer(file);
    });
    
    input.click();
    return completer.future;
  }
}
