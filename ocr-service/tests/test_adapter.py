import io
import sys
import unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from adapter import adapt, table_rows
from main import app, slot
from fastapi.testclient import TestClient
from PIL import Image
from image_processing import prepare_image, enhance_image

HTML='<table><tr><th>Tên hàng</th><th>SL</th><th>Đơn giá</th><th>Thành tiền</th></tr><tr><td>Cơm gà</td><td>2</td><td>45.000</td><td>90.000</td></tr></table>'
SAMPLE={'res':{'overall_ocr_res':{'rec_texts':['Cơm gà','90.000'], 'rec_boxes':[[10,20,80,40],[200,20,270,40]],'rec_scores':[.98,.65]},'table_res_list':[{'pred_html':HTML}]}}
class AdapterTests(unittest.TestCase):
    def test_geometry(self):
        r=adapt(SAMPLE,'structure'); self.assertEqual(r['words'][0]['confidence'],98);self.assertEqual(r['tables'][0][1][2],'45.000');self.assertEqual(r['words'][0]['text'],'Cơm gà')
    def test_polygon_geometry(self):
        result=adapt({'rec_texts':['Cơm'],'rec_polys':[[[10,20],[80,18],[82,40],[12,42]]],'rec_scores':[.99]},'ocr')
        self.assertEqual((result['words'][0]['x0'],result['words'][0]['y0'],result['words'][0]['x1'],result['words'][0]['y1']),(10,18,82,42))
    def test_long_receipt_preserves_small_print(self):
        image=io.BytesIO();Image.new('RGB',(800,5000),'white').save(image,format='PNG')
        self.assertEqual(prepare_image(image.getvalue()).size,(800,5000))
    def test_alpha_composites_on_white(self):
        image=io.BytesIO();Image.new('RGBA',(30,20),(0,0,0,0)).save(image,format='PNG')
        self.assertEqual(prepare_image(image.getvalue()).getpixel((0,0)),(255,255,255))
    def test_exif_rotation(self):
        image=io.BytesIO();source=Image.new('RGB',(30,20),'white');exif=source.getexif();exif[274]=6;source.save(image,format='JPEG',exif=exif)
        self.assertEqual(prepare_image(image.getvalue()).size,(20,30))
    def test_enhance_keeps_geometry(self):
        self.assertEqual(enhance_image(Image.new('RGB',(30,20),'white')).size,(30,20))
    def test_merged(self): self.assertIsNone(table_rows(HTML.replace('<td>2','<td colspan="2">2')))
    def test_ragged(self): self.assertIsNone(table_rows(HTML.replace('<td>2</td>','')))
    def test_ocr_only(self): self.assertEqual(adapt(SAMPLE,'ocr')['tables'],[])
    def test_inconsistent(self):
        with self.assertRaises(ValueError): adapt({'rec_texts':['1'],'rec_boxes':[],'rec_scores':[.8]},'ocr')
    def test_nan(self):
        with self.assertRaises(ValueError): adapt({'rec_texts':['1'],'rec_boxes':[[0,0,10,10]],'rec_scores':[float('nan')]},'ocr')
    def test_health(self): self.assertEqual(TestClient(app).get('/health').json()['status'],'up')
    def test_bad_image(self): self.assertEqual(TestClient(app).post('/recognize',content=b'bad').status_code,400)
    def test_bad_mode(self): self.assertEqual(TestClient(app).post('/recognize?mode=bad',content=b'bad').status_code,400)
    def test_large_image(self): self.assertEqual(TestClient(app).post('/recognize',content=b'0'*(8*1024*1024+1)).status_code,413)
    def test_busy(self):
        slot.acquire()
        try:self.assertEqual(TestClient(app).post('/recognize',content=b'x').status_code,429)
        finally:slot.release()
    def test_mock_inference(self):
        class Model:
            def predict(self,array):
                assert array.shape==(20,30,3)
                return [type('Result',(),{'json':SAMPLE})()]
        img=io.BytesIO();Image.new('RGB',(30,20),'white').save(img,format='PNG')
        with patch('main.load_model',return_value=Model()):
            response=TestClient(app).post('/recognize?mode=structure',content=img.getvalue())
        self.assertEqual(response.status_code,200);self.assertEqual(response.json()['tables'][0][1][3],'90.000')
    def test_low_confidence_retries_without_losing_original(self):
        class Model:
            calls=0
            def predict(self,array):
                self.calls+=1
                if self.calls==2:
                    raise RuntimeError('Retry unavailable')
                return [type('Result',(),{'json':SAMPLE})()]
        model=Model();img=io.BytesIO();Image.new('RGB',(30,20),'white').save(img,format='PNG')
        with patch('main.load_model',return_value=model):
            response=TestClient(app).post('/recognize?mode=ocr',content=img.getvalue())
        self.assertEqual(response.status_code,200);self.assertEqual(model.calls,2)
        self.assertEqual(response.json()['words'][0]['text'],'Cơm gà')
    def test_empty_first_pass_can_recover(self):
        class Model:
            calls=0
            def predict(self,array):
                self.calls+=1
                return [] if self.calls==1 else [type('Result',(),{'json':SAMPLE})()]
        model=Model();img=io.BytesIO();Image.new('RGB',(30,20),'white').save(img,format='PNG')
        with patch('main.load_model',return_value=model):
            response=TestClient(app).post('/recognize?mode=ocr',content=img.getvalue())
        self.assertEqual(response.status_code,200);self.assertEqual(model.calls,2)
if __name__=='__main__': unittest.main()
