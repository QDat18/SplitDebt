import 'dart:js_interop';
import 'dart:typed_data';

@JS('splitDebtRecognizeReceipt')
external JSPromise<JSString> _recognize(JSUint8Array bytes);

@JS('splitDebtDecodeReceiptQr')
external JSPromise<JSString> _decodeQr(JSUint8Array bytes);

Future<String> recognizeReceipt(Uint8List bytes, String path) async {
  final result = await _recognize(bytes.toJS).toDart;
  return result.toDart;
}

Future<String?> decodeReceiptQrImage(Uint8List bytes) async {
  final result = (await _decodeQr(bytes.toJS).toDart).toDart;
  return result.isEmpty ? null : result;
}
