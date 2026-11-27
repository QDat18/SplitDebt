// Trách nhiệm file: Lưu trữ phiên bản và nội dung văn bản pháp lý đóng gói sẵn trong ứng dụng.

const String kTermsVersion = '2026-11-26';
const String kPrivacyVersion = '2026-11-26';
const String kLegalChangeSummary =
    'Cập nhật điều khoản về xử lý dữ liệu cá nhân, quyền xem dữ liệu và xoá tài khoản theo quy định mới.';

enum LegalDocType { privacy, terms }

class LegalSection {
  final String title;
  final List<String> paragraphs;

  const LegalSection(this.title, this.paragraphs);
}

const List<LegalSection> kPrivacySections = [
  LegalSection(
    '1. Bên kiểm soát dữ liệu và thông tin liên hệ',
    [
      'Đơn vị phát triển: Nhóm phát triển SplitDebt ([CẦN ĐIỀN]).',
      'Email liên hệ về dữ liệu cá nhân: [CẦN ĐIỀN].',
    ],
  ),
  LegalSection(
    '2. Dữ liệu cá nhân được thu thập',
    [
      'Thông tin tài khoản: họ tên, email, số điện thoại (nếu bạn tự nhập), mật khẩu đã được băm an toàn.',
      'Dữ liệu nhóm và công nợ: danh sách nhóm, vai trò, khoản chi tiêu, phần chia, thanh toán và tin nhắn nhóm.',
      'Ảnh đại diện, mã thông báo đẩy (push token), nền tảng thiết bị, phiên bản ứng dụng và lịch sử các lần bạn đồng ý.',
      'Tính năng Quét hoá đơn xử lý ảnh và chữ hoàn toàn ngay trên điện thoại của bạn. Ảnh và nội dung thô không được gửi về máy chủ hay bất kỳ bên thứ ba nào.',
    ],
  ),
  LegalSection(
    '3. Mục đích và căn cứ xử lý dữ liệu',
    [
      'Xử lý dựa trên sự đồng ý rõ ràng của bạn và để thực hiện dịch vụ quản lý nhóm, khoản chi và công nợ theo yêu cầu.',
      'Ứng dụng không dùng dữ liệu của bạn cho quảng cáo và không tích hợp theo dõi hành vi bên thứ ba.',
    ],
  ),
  LegalSection(
    '4. Bên nhận dữ liệu và nơi lưu trữ',
    [
      'Firebase (Google): nhận push token để gửi thông báo đẩy; dữ liệu có thể được xử lý ở nước ngoài.',
      'Supabase: lưu ảnh đại diện bạn tải lên; dữ liệu có thể được lưu ở nước ngoài tuỳ vùng máy chủ.',
      'Nhà cung cấp hosting backend và cơ sở dữ liệu: lưu trữ tài khoản, nhóm, khoản chi, thanh toán, tin nhắn và nhật ký đồng ý.',
    ],
  ),
  LegalSection(
    '5. Thời gian lưu trữ và xoá dữ liệu',
    [
      'Dữ liệu được lưu giữ trong suốt thời gian tài khoản hoạt động.',
      'Khi bạn xoá tài khoản, thông tin nhận diện cá nhân, push token, cài đặt, thông báo và nhật ký hoạt động bị xoá hoặc ẩn danh ngay lập tức. Tin nhắn nhóm được thay bằng "Tin nhắn đã bị xoá".',
      'Các khoản chi và thanh toán trong nhóm được giữ lại dưới dạng ẩn danh để không làm sai lệch sổ nợ của thành viên khác. Bản ghi đồng ý được giữ làm bằng chứng tuân thủ.',
    ],
  ),
  LegalSection(
    '6. Quyền của bạn và cách thực hiện',
    [
      'Xem và sao chép dữ liệu của mình tại Cá nhân > Quyền riêng tư > Xem dữ liệu của tôi.',
      'Chỉnh sửa họ tên, số điện thoại, ảnh đại diện tại Hồ sơ cá nhân.',
      'Bật hoặc tắt thông báo trong Cài đặt của điện thoại.',
      'Xoá tài khoản tại Cá nhân > Quyền riêng tư > Xoá tài khoản. Thời hạn phản hồi yêu cầu qua email tối đa 30 ngày.',
    ],
  ),
  LegalSection(
    '7. Biện pháp bảo vệ và độ tuổi',
    [
      'Kết nối được mã hoá HTTPS, mật khẩu được băm bcrypt, quyền truy cập kiểm soát theo nhóm.',
      'Ứng dụng chỉ dành cho người dùng từ đủ 16 tuổi trở lên.',
    ],
  ),
  LegalSection(
    '8. Thay đổi chính sách và căn cứ pháp lý',
    [
      'Khi chính sách thay đổi, phiên bản mới sẽ được cập nhật và yêu cầu bạn đồng ý lại trong ứng dụng.',
      'Văn bản được xây dựng theo Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 và Nghị định 356/2025/NĐ-CP.',
    ],
  ),
];

const List<LegalSection> kTermsSections = [
  LegalSection(
    '1. Mô tả dịch vụ',
    [
      'SplitDebt là công cụ hỗ trợ ghi nhận chi tiêu nhóm, chia tiền và theo dõi công nợ giữa các thành viên.',
      'Ứng dụng không giữ tiền hộ, không trung gian thanh toán và không thực hiện giao dịch chuyển tiền thật.',
    ],
  ),
  LegalSection(
    '2. Điều kiện và trách nhiệm tài khoản',
    [
      'Bạn phải từ đủ 16 tuổi trở lên để đăng ký và sử dụng SplitDebt.',
      'Bạn chịu trách nhiệm bảo mật mật khẩu và mọi hoạt động phát sinh từ tài khoản của mình.',
    ],
  ),
  LegalSection(
    '3. Các hành vi bị cấm',
    [
      'Không gửi nội dung lừa đảo, xúc phạm, quấy rối hoặc vi phạm pháp luật Việt Nam trong tin nhắn nhóm.',
      'Không mạo danh người khác, không tạo khoản chi giả mạo hoặc can thiệp trái phép vào hệ thống.',
    ],
  ),
  LegalSection(
    '4. Giới hạn trách nhiệm',
    [
      'Việc thanh toán thực tế là thoả thuận trực tiếp giữa các thành viên.',
      'Khi dùng Quét hoá đơn trên thiết bị, bạn có trách nhiệm kiểm tra lại tên món và số tiền trước khi lưu.',
    ],
  ),
  LegalSection(
    '5. Chấm dứt tài khoản và luật áp dụng',
    [
      'Bạn có thể xoá tài khoản trong Trung tâm Quyền riêng tư sau khi hoàn tất công nợ trong các nhóm.',
      'Điều khoản này được điều chỉnh theo pháp luật Việt Nam.',
    ],
  ),
];

