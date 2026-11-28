"""Warm both models in the running server; checks a real sample, not just imports."""
import json
from pathlib import Path
from urllib.request import Request, urlopen

sample = Path(__file__).with_name('sample.png')
if not sample.exists():
    sample = Path(__file__).resolve().parent.parent / 'docs/ocr-test/receipt-sample.png'
image = sample.read_bytes()
for mode in ('ocr', 'structure'):
    req = Request(f'http://127.0.0.1:8002/recognize?mode={mode}', data=image,
                  headers={'Content-Type': 'application/octet-stream'})
    with urlopen(req, timeout=1800) as response:
        result = json.load(response)
    if not result.get('text', '').strip() or not result.get('words'):
        raise RuntimeError(f'{mode}: empty recognition result')
    print(f'{mode}: sample recognized ({len(result["words"])} regions)')
