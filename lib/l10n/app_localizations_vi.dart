// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Bondy';

  @override
  String get loading => 'Đang tải...';

  @override
  String get error => 'Đã xảy ra lỗi';

  @override
  String get retry => 'Thử lại';

  @override
  String get cancel => 'Hủy';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get save => 'Lưu';

  @override
  String get next => 'Tiếp theo';

  @override
  String get back => 'Quay lại';

  @override
  String get done => 'Hoàn thành';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get loginTitle => 'Đăng nhập';

  @override
  String get emailHint => 'Email của bạn';

  @override
  String get passwordHint => 'Mật khẩu';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get noAccount => 'Chưa có tài khoản? Đăng ký';

  @override
  String get registerTitle => 'Đăng ký';

  @override
  String get otpTitle => 'Nhập mã OTP';

  @override
  String otpSentTo(String email) {
    return 'Mã OTP đã gửi đến $email';
  }

  @override
  String get profileSetupTitle => 'Thiết lập hồ sơ';

  @override
  String get discoverTitle => 'Khám phá';

  @override
  String get matchesTitle => 'Kết nối';

  @override
  String get healingTitle => 'Chữa lành';

  @override
  String get sendMessage => 'Gửi tin nhắn';

  @override
  String get typeMessage => 'Nhập tin nhắn...';

  @override
  String get matchConfirmed => 'Kết nối đã được xác nhận! 🎉';

  @override
  String get reportUser => 'Báo cáo người dùng';

  @override
  String get blockUser => 'Chặn người dùng';

  @override
  String get unmatch => 'Hủy kết nối';

  @override
  String get deleteAccount => 'Xóa tài khoản';

  @override
  String get deleteAccountConfirm => 'Bạn có chắc muốn xóa tài khoản không?';

  @override
  String get crisisHotline => 'Tâm Đồng Viên';

  @override
  String get delete => 'Xóa';

  @override
  String get chatTitle => 'Tin nhắn';

  @override
  String get profileTitle => 'Cá nhân';

  @override
  String get safetyCheckinTitle => 'Check-in an toàn';

  @override
  String get safetyCheckinDesc =>
      'Bật check-in để đảm bảo an toàn trước buổi hẹn gặp offline';

  @override
  String get iAmSafe => 'Tôi an toàn';

  @override
  String get weeklyReportTitle => 'Báo cáo tuần';

  @override
  String get promptsTitle => '3 câu nói về bạn';

  @override
  String get addPrompt => 'Thêm câu trả lời';

  @override
  String get vibeTitle => 'Vibe / Phong cách';

  @override
  String get vibeChill => 'Nhẹ nhàng';

  @override
  String get vibeSerious => 'Nghiêm túc';

  @override
  String get vibeAdventurous => 'Năng động';

  @override
  String get vibeCreative => 'Sáng tạo';

  @override
  String get vibeIntellectual => 'Trí tuệ';

  @override
  String get vibePlayful => 'Vui vẻ';

  @override
  String get healingGateTitle => 'Check-in cảm xúc trước khi gặp người mới';

  @override
  String get healingGateDesc =>
      'Bondy gợi ý bạn dành 2 phút check-in cảm xúc hôm nay trước khi khám phá.';

  @override
  String get checkInNow => 'Check-in ngay';

  @override
  String get later => 'Để sau';

  @override
  String get compatibilityReceiptTitle => 'Tại sao 2 bạn match?';

  @override
  String get openChat => 'Mở chat';
}
