import logging
import os
import threading
from fastapi import FastAPI, HTTPException, Request
from starlette.concurrency import run_in_threadpool
from PIL import Image, UnidentifiedImageError
from adapter import adapt
from image_processing import prepare_image, enhance_image, needs_retry, recognition_quality

app = FastAPI(title='SplitDebt Local OCR')
MAX_BYTES = 8 * 1024 * 1024
Image.MAX_IMAGE_PIXELS = 16_000_000
log = logging.getLogger('uvicorn.error')
slot = threading.Lock()
models = {}
warmed = set()


def load_model(mode):
    if mode not in models:
        from paddleocr import PaddleOCR, PPStructureV3
        common = dict(device='cpu', enable_mkldnn=False, cpu_threads=max(1, min(8, int(os.environ.get('OCR_CPU_THREADS', '4')))),
                      text_detection_model_name='PP-OCRv5_mobile_det',
                      text_recognition_model_name='latin_PP-OCRv5_mobile_rec',
                      use_doc_orientation_classify=True, use_doc_unwarping=True,
                      use_textline_orientation=True)
        if mode == 'structure':
            models[mode] = PPStructureV3(**common, use_table_recognition=True,
                                         use_formula_recognition=False, use_seal_recognition=False,
                                         use_chart_recognition=False)
        else:
            models[mode] = PaddleOCR(**common)
    return models[mode]


def recognize(data, mode):
    if not slot.acquire(blocking=False):
        raise HTTPException(429, 'OCR is busy')
    try:
        try:
            image = prepare_image(data)
        except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError, Image.DecompressionBombWarning):
            raise HTTPException(400, 'Invalid JPEG/PNG image') from None
        import numpy as np
        # Paddle consumes BGR arrays. No image is written to disk.
        model = load_model(mode)
        def infer(candidate_image):
            array = np.ascontiguousarray(np.asarray(candidate_image)[:, :, ::-1])
            result = next(iter(model.predict(array)), None)
            if result is None:
                return None
            try:
                return adapt(result.json, mode)
            except (ValueError, TypeError, KeyError):
                return None
        first = infer(image)
        if first is not None and (mode == 'structure' or not needs_retry(first)):
            warmed.add(mode)
            return first
        # Run expensive document/table recognition once. Only OCR retries an unclear image.
        try:
            second = infer(enhance_image(image)) if mode == 'ocr' else None
        except Exception:
            if first is None:
                raise
            # Enhancement is a best-effort retry; preserve the usable original result.
            second = None
        candidates = [payload for payload in (first, second) if payload is not None]
        if not candidates:
            raise HTTPException(422, 'OCR result is empty or invalid')
        warmed.add(mode)
        return max(candidates, key=recognition_quality)
    except HTTPException:
        raise
    except Exception as exc:
        # Do not log user OCR text or image bytes.
        log.error('OCR engine failed: %s', type(exc).__name__)
        raise HTTPException(503, 'Local OCR model unavailable; see service console') from None
    finally:
        slot.release()


@app.get('/health')
def health():
    return {'status': 'up', 'loaded': list(models), 'ready': sorted(warmed), 'busy': slot.locked()}


@app.post('/recognize')
async def scan(request: Request, mode: str = 'ocr'):
    if mode not in ('ocr', 'structure'):
        raise HTTPException(400, 'Unknown OCR mode')
    data = bytearray()
    async for chunk in request.stream():
        if len(data) + len(chunk) > MAX_BYTES:
            raise HTTPException(413, 'Image too large')
        data.extend(chunk)
    if not data:
        raise HTTPException(400, 'Missing image')
    return await run_in_threadpool(recognize, bytes(data), mode)
