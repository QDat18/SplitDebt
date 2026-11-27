(() => {
  let scriptPromise;
  let workerPromise;
  let qrLibraryPromise;
  let queue = Promise.resolve();
  function loadLibrary() {
    if (window.Tesseract) return Promise.resolve();
    if (!scriptPromise) {
      scriptPromise = new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/tesseract.js@6.0.1/dist/tesseract.min.js';
        const timer = setTimeout(() => {
          script.remove(); reject(new Error('OCR library download timed out'));
        }, 30000);
        script.onload = () => { clearTimeout(timer); resolve(); };
        script.onerror = () => { clearTimeout(timer); script.remove(); reject(new Error('OCR library unavailable')); };
        document.head.appendChild(script);
      }).catch(error => { scriptPromise = undefined; throw error; });
    }
    return scriptPromise;
  }
  async function enhanced(blob) {
    const image = await createImageBitmap(blob);
    try {
      const scale = Math.min(2, 2800 / Math.max(image.width, image.height));
      const canvas = document.createElement('canvas');
      canvas.width = Math.max(1, Math.round(image.width * scale));
      canvas.height = Math.max(1, Math.round(image.height * scale));
      const ctx = canvas.getContext('2d', {willReadFrequently: true});
      ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
      const data = ctx.getImageData(0, 0, canvas.width, canvas.height);
      const hist = new Uint32Array(256);
      for (let i = 0; i < data.data.length; i += 4) {
        const g = Math.round(data.data[i]*.299 + data.data[i+1]*.587 + data.data[i+2]*.114);
        hist[g]++; data.data[i] = data.data[i+1] = data.data[i+2] = g;
      }
      const count = canvas.width * canvas.height;
      let low = 0, high = 255, a = 0, b = 0;
      while (low < 255 && a + hist[low] < count * .02) a += hist[low++];
      while (high > 0 && b + hist[high] < count * .02) b += hist[high--];
      if (high - low > 25) for (let i = 0; i < data.data.length; i += 4) {
        const v = Math.round(Math.max(0, Math.min(255, (data.data[i]-low)*255/(high-low))));
        data.data[i] = data.data[i+1] = data.data[i+2] = v;
      }
      ctx.putImageData(data,0,0);
      return canvas;
    } finally { image.close(); }
  }
  async function recognize(bytes) {
    await loadLibrary();
    if (!workerPromise) {
      workerPromise = window.Tesseract.createWorker(['vie', 'eng'], 1).catch(error => {
        workerPromise = undefined; throw error;
      });
    }
    const worker = await workerPromise;
    try {
      const blob = new Blob([bytes]);
      await worker.setParameters({tessedit_pageseg_mode: '6', preserve_interword_spaces: '1'});
      const first = await worker.recognize(blob, {rotateAuto: true}, {text: true, blocks: true});
      // Retry only on low confidence/short text to avoid doubling ordinary scan time.
      if (first.data.confidence >= 82 && first.data.text.trim().length >= 20) return payload(first.data);
      let alternative;
      try {
        const canvas = await enhanced(blob);
        await worker.setParameters({tessedit_pageseg_mode: '4', preserve_interword_spaces: '1'});
        alternative = await worker.recognize(canvas, {rotateAuto: true}, {text: true, blocks: true});
      } catch (_) { return payload(first.data); }
      return payload(alternative.data.confidence > first.data.confidence + 2 && alternative.data.text.trim().length >= first.data.text.trim().length * .65
        ? alternative.data : first.data);
    } catch (error) {
      workerPromise = undefined;
      try { await worker.terminate(); } catch (_) { /* cleanup best effort */ }
      throw error;
    }
  }
  function payload(data) {
    const words = [];
    for (const block of data.blocks || []) {
      for (const paragraph of block.paragraphs || []) {
        for (const line of paragraph.lines || []) {
          for (const word of line.words || []) {
            const b = word.bbox;
            if (!b || !word.text || b.x1 <= b.x0 || b.y1 <= b.y0) continue;
            words.push({text: word.text, x0: b.x0, y0: b.y0, x1: b.x1, y1: b.y1,
              confidence: Number.isFinite(word.confidence) ? word.confidence : null});
          }
        }
      }
    }
    return JSON.stringify({text: data.text, words: words.length > 1500 ? [] : words});
  }

  // Image import works even when the user has denied camera permission.
  window.splitDebtDecodeReceiptQr = async bytes => {
    const blob = new Blob([bytes]);
    if ('BarcodeDetector' in window) {
      try {
        const bitmap = await createImageBitmap(blob);
        try {
          const codes = await new BarcodeDetector({formats: ['qr_code']}).detect(bitmap);
          if (codes.length) return codes[0].rawValue;
        } finally { bitmap.close(); }
      } catch (_) { /* Older browsers use the same ZXing version as mobile_scanner. */ }
    }
    if (!window.ZXing) {
      if (!qrLibraryPromise) qrLibraryPromise = new Promise((resolve, reject) => {
        const script = document.createElement('script');
        const timer = setTimeout(() => {script.remove(); reject(new Error('QR download timed out'));}, 20000);
        script.src = 'https://unpkg.com/@zxing/library@0.21.3/umd/index.min.js';
        script.onload = () => {clearTimeout(timer); resolve();};
        script.onerror = () => {clearTimeout(timer); script.remove(); reject(new Error('QR reader unavailable'));};
        document.head.appendChild(script);
      }).catch(error => {qrLibraryPromise = undefined; throw error;});
      await qrLibraryPromise;
    }
    const url = URL.createObjectURL(blob);
    const reader = new window.ZXing.BrowserQRCodeReader();
    try {
      const result = await reader.decodeFromImageUrl(url);
      return result.getText();
    } catch (error) {
      if (error && (error.name === 'NotFoundException' || error.name === 'FormatException' || error.name === 'ChecksumException')) return '';
      throw error;
    } finally {reader.reset(); URL.revokeObjectURL(url);}
  };
  window.splitDebtRecognizeReceipt = bytes => {
    const job = queue.then(() => recognize(bytes));
    queue = job.catch(() => {});
    return job;
  };
})();
