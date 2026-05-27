import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'bondy_exceptions.dart';

/// Chuẩn hóa thông báo lỗi hiển thị cho người dùng — không dùng [Object.toString].
class BondyErrorMapper {
  BondyErrorMapper._();

  static String message(Object? error) {
    if (error == null) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }

    if (error is String) {
      return _clean(error);
    }

    if (error is ApiClientException) {
      return _mapApi(error);
    }
    if (error is AuthRequiredException) {
      return error.message;
    }
    if (error is SessionExpiredException) {
      return error.message;
    }
    if (error is AuthServiceException) {
      return _clean(error.message);
    }
    if (error is QuotaExceededException) {
      return error.message;
    }
    if (error is TimeoutException) {
      return 'Kết nối quá lâu. Kiểm tra mạng và thử lại.';
    }
    if (error is SocketException) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra Internet.';
    }
    if (error is HandshakeException || error is TlsException) {
      return 'Kết nối bảo mật thất bại. Thử lại sau vài phút.';
    }
    if (error is FormatException) {
      return 'Dữ liệu nhận về không hợp lệ. Vui lòng thử lại.';
    }
    if (error is PlatformException) {
      return _clean(error.message ?? 'Không thực hiện được thao tác trên thiết bị.');
    }
    if (error is StateError) {
      return _clean(error.message);
    }
    if (error is ArgumentError) {
      return _clean(error.message);
    }

    final raw = error.toString();
    if (_looksLikeTechnicalDump(raw)) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
    return _clean(raw);
  }

  static String? code(Object? error) {
    if (error is ApiClientException) return error.code;
    return null;
  }

  static String _mapApi(ApiClientException error) {
    final code = error.code;
    if (code == 'PROFILE_INCOMPLETE') {
      return 'Vui lòng hoàn thành hồ sơ (ảnh, sở thích, khảo sát, vị trí) để tiếp tục.';
    }
    if (code == 'UNAUTHORIZED' || error.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (error.statusCode == 403) {
      return _clean(error.message).isNotEmpty
          ? _clean(error.message)
          : 'Bạn không có quyền thực hiện thao tác này.';
    }
    if (error.statusCode == 404) {
      return _clean(error.message).isNotEmpty
          ? _clean(error.message)
          : 'Không tìm thấy nội dung yêu cầu.';
    }
    if (error.statusCode != null && error.statusCode! >= 500) {
      return 'Máy chủ đang bận. Vui lòng thử lại sau.';
    }
    return _clean(error.message);
  }

  static String _clean(String? value) {
    var text = (value ?? '').trim();
    
    // Loại bỏ các tiền tố Exception/Error phổ biến để lấy thông báo thực tế
    if (text.toLowerCase().startsWith('exception:')) {
      text = text.substring(10).trim();
    } else if (text.toLowerCase().startsWith('exception')) {
      text = text.substring(9).trim();
    }
    if (text.toLowerCase().startsWith('error:')) {
      text = text.substring(6).trim();
    } else if (text.toLowerCase().startsWith('error')) {
      text = text.substring(5).trim();
    }

    if (text.isEmpty) return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    if (_looksLikeTechnicalDump(text)) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
    return text;
  }

  static bool _looksLikeTechnicalDump(String text) {
    final lower = text.toLowerCase();
    return lower.contains('stacktrace') ||
        lower.contains('dart:') ||
        lower.contains('clientexception') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.startsWith('instance of ') ||
        text.length > 200;
  }
}
