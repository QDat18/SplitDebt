"""Bounded, reversible image preparation for photographed receipts."""
import io
import warnings
from PIL import Image, ImageEnhance, ImageOps

MAX_PIXELS = 16_000_000


def prepare_image(data):
    with warnings.catch_warnings():
        warnings.simplefilter('error', Image.DecompressionBombWarning)
        with Image.open(io.BytesIO(data)) as source:
            if source.format not in ('JPEG', 'PNG') or source.width * source.height > MAX_PIXELS:
                raise ValueError('Unsupported image')
            image = ImageOps.exif_transpose(source)
            # Camera exports and screenshots can contain alpha. Composite onto receipt paper.
            if image.mode in ('RGBA', 'LA') or 'transparency' in image.info:
                rgba = image.convert('RGBA')
                background = Image.new('RGBA', rgba.size, 'white')
                background.alpha_composite(rgba)
                image = background.convert('RGB')
            else:
                image = image.convert('RGB')
    # Preserve narrow, long receipts; a 2800px longest-edge cap erased small print.
    scale = min(1.0, 6000 / max(image.size), (12_000_000 / (image.width * image.height)) ** .5)
    if scale < 1:
        image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
    return image


def enhance_image(image):
    # Keep the original pass. Faded thermal paper can benefit from a second, mild pass;
    # aggressive binarization destroys thin accents and decimal separators.
    grayscale = ImageOps.autocontrast(image.convert('L'), cutoff=1)
    return ImageEnhance.Sharpness(grayscale).enhance(1.25).convert('RGB')


def recognition_quality(payload):
    words = payload['words']
    if not words:
        return 0
    confidences = [word['confidence'] for word in words]
    digits = sum(character.isdecimal() for character in payload['text'])
    # Confidence dominates; bounded coverage prevents a noisy long result winning by size.
    return sum(confidences) / len(confidences) + min(12, digits / 5) + min(8, len(words) / 5)


def needs_retry(payload):
    words = payload['words']
    return (not words or sum(word['confidence'] for word in words) / len(words) < 82
            or sum(character.isdecimal() for character in payload['text']) < 6)
