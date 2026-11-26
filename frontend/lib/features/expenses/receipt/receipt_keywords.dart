// Trách nhiệm file: Chứa danh sách từ khoá chuẩn hoá (không dấu, chữ thường) để phân loại các dòng trên hoá đơn.

class ReceiptKeywords {
  static const List<String> ignoreAlways = [
    'tien khach dua',
    'khach dua',
    'khach thanh toan',
    'khach tra',
    'da thanh toan',
    'tien thua',
    'tra lai',
    'tien mat',
    'chuyen khoan',
    'thanh toan the',
    'quet the',
    'the:',
    'the tin dung',
    'visa',
    'master',
    'atm',
    'momo',
    'zalopay',
    'vnpay',
    'sl:',
    'so ban',
    'ban so',
    'ban:',
    'gio vao',
    'gio ra',
    'thu ngan',
    'nhan vien',
    'hotline',
    'dt:',
    'dt',
    'tel',
    'phone',
    'dien thoai',
    'sdt',
    'mst',
    'dia chi',
    'wifi',
    'cam on',
    'hen gap lai',
    'so hd',
    'ma hd',
    'hoa don',
    'so luong',
    'tong so luong',
    'tong sl',
    'so mat hang',
    'so luong mat hang',
    'diem tich luy',
    'diem thuong',
    'ma kh',
    'ma khach hang',
    'the thanh vien',
    'hang thanh vien',
    'pos',
    'so phieu',
    'ngay in',
    'thue suat',
    'tien thue',
  ];

  static const List<String> ignoreWhenNoMoney = [
    'don gia',
    'thanh tien',
    'ten mon',
    'sl',
    'gia',
    't.tien',
    'tt',
    'mat hang',
    'ten hang',
  ];

  static const List<String> total = [
    'tong thanh toan',
    'thanh toan',
    'tong cong',
    'tong tien',
    'can thanh toan',
    'khach can tra',
    'can tra',
    'total',
  ];

  static const List<String> subtotal = [
    'tong tien hang',
    'tien hang',
    'tam tinh',
    'cong tien hang',
    'sub total',
    'subtotal',
  ];

  static const List<String> vat = [
    'vat',
    'thue',
  ];

  static const List<String> vatIncluded = [
    'da bao gom',
    'included',
  ];

  static const List<String> service = [
    'phi dich vu',
    'phi phuc vu',
    'service',
  ];

  static const List<String> discount = [
    'giam gia',
    'chiet khau',
    'khuyen mai',
    'discount',
    'voucher',
  ];
}
