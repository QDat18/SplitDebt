"""Convert Paddle results to the SplitDebt contract; no model dependency here."""
import math
from html.parser import HTMLParser


class PlainTable(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.rows = []
        self.row = None
        self.cell = None
        self.invalid = False
        self.tables = 0

    def handle_starttag(self, tag, attrs):
        if tag == 'table':
            self.tables += 1
        if tag == 'tr':
            if self.row is not None:
                self.invalid = True
            self.row = []
        if tag in ('td', 'th'):
            if self.row is None or self.cell is not None or any(k in ('rowspan', 'colspan') and v != '1' for k, v in attrs):
                self.invalid = True
            self.cell = []
        if tag == 'br' and self.cell is not None:
            self.cell.append(' ')

    def handle_data(self, data):
        if self.cell is not None:
            self.cell.append(data)

    def handle_endtag(self, tag):
        if tag in ('td', 'th') and self.row is not None and self.cell is not None:
            self.row.append(' '.join(''.join(self.cell).split()))
            self.cell = None
        if tag == 'tr' and self.row is not None:
            self.rows.append(self.row)
            self.row = None


def table_rows(html):
    if not isinstance(html, str) or len(html) > 200000:
        return None
    parser = PlainTable()
    parser.feed(html)
    parser.close()
    rows = parser.rows
    if parser.invalid or parser.tables != 1 or parser.row is not None or parser.cell is not None or not 2 <= len(rows) <= 101:
        return None
    width = len(rows[0])
    if not 2 <= width <= 12 or any(len(row) != width or any(len(cell) > 200 for cell in row) for row in rows):
        return None
    return rows


def adapt(result, mode):
    data = result.get('res', result)
    ocr = data.get('overall_ocr_res', data)
    texts = ocr.get('rec_texts', [])
    boxes = ocr.get('rec_boxes')
    if boxes is None:
        # Both are actual model geometry. Some Paddle pipelines expose polygons only.
        boxes = ocr.get('rec_polys', [])
    scores = ocr.get('rec_scores', [])
    if len(texts) != len(boxes) or len(texts) != len(scores) or len(texts) > 1500:
        raise ValueError('OCR output exceeds limit or has inconsistent coordinates')
    words = []
    raw = []
    for text, box, score in zip(texts, boxes, scores):
        text = str(text).strip()
        if not text:
            continue
        raw.append(text)
        if len(box) == 4 and all(hasattr(point, '__len__') and len(point) == 2 for point in box):
            coordinates = [(float(point[0]), float(point[1])) for point in box]
            x0, y0 = min(point[0] for point in coordinates), min(point[1] for point in coordinates)
            x1, y1 = max(point[0] for point in coordinates), max(point[1] for point in coordinates)
        else:
            x0, y0, x1, y1 = map(float, box)
        score = float(score)
        if len(text) > 200 or not all(math.isfinite(v) for v in (x0, y0, x1, y1, score)) or not (0 <= x0 < x1 <= 20000 and 0 <= y0 < y1 <= 20000 and 0 <= score <= 1):
            raise ValueError('Invalid OCR geometry')
        # Paddle returns line/cell regions, not word boxes. Never fabricate per-word positions.
        words.append(dict(text=text, x0=x0, y0=y0, x1=x1, y1=y1, confidence=score*100))
    text = '\n'.join(raw)
    if not text or len(text) > 24000:
        raise ValueError('Empty or oversized recognition')
    tables = []
    if mode == 'structure':
        for table in data.get('table_res_list', [])[:10]:
            rows = table_rows(table.get('pred_html'))
            if rows is not None:
                tables.append(rows)
    return dict(text=text, words=words, tables=tables, engine=mode)
