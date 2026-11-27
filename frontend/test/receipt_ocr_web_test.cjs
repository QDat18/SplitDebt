const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

// Exercise the public browser bridge with model-independent OCR output. This
// catches regressions that discard word geometry before it reaches /parse.
async function main() {
  const calls = [];
  const data = {text: 'Tên hàng SL Đơn giá Thành tiền\nCơm 2 45000 90000', confidence: 96,
    blocks: [{paragraphs: [{lines: [{words: [
      {text: 'Cơm', bbox: {x0: 10, y0: 40, x1: 80, y1: 60}, confidence: 94},
      {text: '90000', bbox: {x0: 360, y0: 40, x1: 420, y1: 60}, confidence: 98},
    ]}]}]}]};
  const worker = {setParameters: async () => {}, recognize: async (...args) => {calls.push(args); return {data};}};
  const context = {window: {Tesseract: {createWorker: async () => worker}}, Blob, setTimeout, clearTimeout,
    URL, Uint32Array, Promise};
  vm.runInNewContext(fs.readFileSync('frontend/web/receipt_ocr.js', 'utf8'), context);
  const result = JSON.parse(await context.window.splitDebtRecognizeReceipt(new Uint8Array([1, 2, 3])));
  assert.equal(result.text, data.text);
  assert.deepEqual(result.words, [
    {text: 'Cơm', x0: 10, y0: 40, x1: 80, y1: 60, confidence: 94},
    {text: '90000', x0: 360, y0: 40, x1: 420, y1: 60, confidence: 98},
  ]);
  assert.equal(calls[0][2].blocks, true, 'Tesseract 6 must explicitly enable blocks');
  assert.equal(calls.length, 1, 'Confident photos should not trigger a second OCR pass');

  let closed = false;
  context.window.BarcodeDetector = class {async detect() {return [{rawValue: 'sample-qr'}];}};
  context.BarcodeDetector = context.window.BarcodeDetector;
  context.createImageBitmap = async () => ({close() {closed = true;}});
  assert.equal(await context.window.splitDebtDecodeReceiptQr(new Uint8Array([4, 5])), 'sample-qr');
  assert.equal(closed, true, 'QR image decoding must release its bitmap');
  console.log('Browser receipt bridge: geometry, explicit blocks, fast path and QR bitmap cleanup passed.');
}
main().catch(error => {console.error(error); process.exitCode = 1;});
