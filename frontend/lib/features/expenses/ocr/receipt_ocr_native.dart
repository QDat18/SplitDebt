import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String> recognizeReceipt(Uint8List bytes, String path) async {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    throw UnsupportedError('OCR chỉ hỗ trợ Android, iOS và Web.');
  }
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(path));
    final words = <Map<String, Object?>>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        for (final word in line.elements) {
          final box = word.boundingBox;
          if (word.text.trim().isEmpty || box.width <= 0 || box.height <= 0) {
            continue;
          }
          words.add({
            'text': word.text,
            'x0': box.left,
            'y0': box.top,
            'x1': box.right,
            'y1': box.bottom,
            'confidence': word.confidence == null
                ? null
                : (word.confidence! * 100).clamp(0, 100),
          });
        }
      }
    }
    // Keep complete text for long receipts rather than dropping their last rows.
    return jsonEncode({
      'text': result.text,
      'words': words.length > 1500 ? [] : words,
    });
  } finally {
    await recognizer.close();
  }
}

Future<String?> decodeReceiptQrImage(Uint8List bytes) =>
    throw UnsupportedError('Use the native QR image scanner.');
