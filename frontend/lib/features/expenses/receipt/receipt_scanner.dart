// Trách nhiệm file: Chọn/chụp ảnh hoá đơn bằng image_picker và nhận diện chữ offline qua ML Kit TextRecognizer.

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'receipt_text_rows.dart';

class ReceiptScanner {
  final ImagePicker _picker;

  ReceiptScanner({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<List<String>?> scan(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(picked.path);
      final recognized = await recognizer.processImage(inputImage);

      final ocrLines = <OcrLine>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final box = line.boundingBox;
          ocrLines.add(
            OcrLine(
              text: line.text,
              top: box.top,
              bottom: box.bottom,
              left: box.left,
            ),
          );
        }
      }

      return buildReceiptRows(ocrLines);
    } finally {
      await recognizer.close();
    }
  }
}
