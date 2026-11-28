import 'package:dio/dio.dart';

String networkErrorMessage(DioException error) {
  if ((error.response?.statusCode ?? 0) >= 500) {
    return error.response?.statusCode == 504
        ? 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.'
        : 'Dịch vụ tạm thời chưa sẵn sàng. Vui lòng thử lại.';
  }
  final data = error.response?.data;
  if (data is Map &&
      data['message'] is String &&
      (data['message'] as String).trim().isNotEmpty) {
    return data['message'] as String;
  }
  switch (error.type) {
    case DioExceptionType.connectionError:
      return 'Không kết nối được máy chủ. Kiểm tra Internet hoặc thử lại sau.';
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.';
    case DioExceptionType.cancel:
      return 'Yêu cầu đã bị hủy.';
    case DioExceptionType.badCertificate:
      return 'Không thể xác thực chứng chỉ máy chủ.';
    case DioExceptionType.badResponse:
      return switch (error.response?.statusCode) {
        400 => 'Dữ liệu yêu cầu không hợp lệ.',
        401 => 'Thông tin đăng nhập không đúng hoặc phiên đã hết hạn.',
        403 => 'Bạn không có quyền thực hiện yêu cầu này.',
        404 =>
          'Không tìm thấy chức năng trên máy chủ. Kiểm tra phiên bản backend.',
        429 => 'Hệ thống đang bận. Vui lòng thử lại.',
        503 => 'Dịch vụ chưa sẵn sàng. Vui lòng thử lại.',
        _ => 'Máy chủ không thể xử lý yêu cầu. Vui lòng thử lại.',
      };
    case DioExceptionType.unknown:
      return 'Không thể hoàn thành yêu cầu. Kiểm tra kết nối và thử lại.';
  }
}
