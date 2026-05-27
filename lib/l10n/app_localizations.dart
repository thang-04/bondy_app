import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Tên ứng dụng
  ///
  /// In vi, this message translates to:
  /// **'Bondy'**
  String get appName;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @next.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo'**
  String get next;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @done.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get done;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @loginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginTitle;

  /// No description provided for @emailHint.
  ///
  /// In vi, this message translates to:
  /// **'Email của bạn'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản? Đăng ký'**
  String get noAccount;

  /// No description provided for @registerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get registerTitle;

  /// No description provided for @otpTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã OTP'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP đã gửi đến {email}'**
  String otpSentTo(String email);

  /// No description provided for @profileSetupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập hồ sơ'**
  String get profileSetupTitle;

  /// No description provided for @discoverTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá'**
  String get discoverTitle;

  /// No description provided for @matchesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối'**
  String get matchesTitle;

  /// No description provided for @healingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chữa lành'**
  String get healingTitle;

  /// No description provided for @sendMessage.
  ///
  /// In vi, this message translates to:
  /// **'Gửi tin nhắn'**
  String get sendMessage;

  /// No description provided for @typeMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tin nhắn...'**
  String get typeMessage;

  /// No description provided for @matchConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối đã được xác nhận! 🎉'**
  String get matchConfirmed;

  /// No description provided for @reportUser.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo người dùng'**
  String get reportUser;

  /// No description provided for @blockUser.
  ///
  /// In vi, this message translates to:
  /// **'Chặn người dùng'**
  String get blockUser;

  /// No description provided for @unmatch.
  ///
  /// In vi, this message translates to:
  /// **'Hủy kết nối'**
  String get unmatch;

  /// No description provided for @deleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa tài khoản không?'**
  String get deleteAccountConfirm;

  /// Tên đường dây tư vấn
  ///
  /// In vi, this message translates to:
  /// **'Tâm Đồng Viên'**
  String get crisisHotline;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @chatTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn'**
  String get chatTitle;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get profileTitle;

  /// No description provided for @safetyCheckinTitle.
  ///
  /// In vi, this message translates to:
  /// **'Check-in an toàn'**
  String get safetyCheckinTitle;

  /// No description provided for @safetyCheckinDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bật check-in để đảm bảo an toàn trước buổi hẹn gặp offline'**
  String get safetyCheckinDesc;

  /// No description provided for @iAmSafe.
  ///
  /// In vi, this message translates to:
  /// **'Tôi an toàn'**
  String get iAmSafe;

  /// No description provided for @weeklyReportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo tuần'**
  String get weeklyReportTitle;

  /// No description provided for @promptsTitle.
  ///
  /// In vi, this message translates to:
  /// **'3 câu nói về bạn'**
  String get promptsTitle;

  /// No description provided for @addPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Thêm câu trả lời'**
  String get addPrompt;

  /// No description provided for @vibeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vibe / Phong cách'**
  String get vibeTitle;

  /// No description provided for @vibeChill.
  ///
  /// In vi, this message translates to:
  /// **'Nhẹ nhàng'**
  String get vibeChill;

  /// No description provided for @vibeSerious.
  ///
  /// In vi, this message translates to:
  /// **'Nghiêm túc'**
  String get vibeSerious;

  /// No description provided for @vibeAdventurous.
  ///
  /// In vi, this message translates to:
  /// **'Năng động'**
  String get vibeAdventurous;

  /// No description provided for @vibeCreative.
  ///
  /// In vi, this message translates to:
  /// **'Sáng tạo'**
  String get vibeCreative;

  /// No description provided for @vibeIntellectual.
  ///
  /// In vi, this message translates to:
  /// **'Trí tuệ'**
  String get vibeIntellectual;

  /// No description provided for @vibePlayful.
  ///
  /// In vi, this message translates to:
  /// **'Vui vẻ'**
  String get vibePlayful;

  /// No description provided for @healingGateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Check-in cảm xúc trước khi gặp người mới'**
  String get healingGateTitle;

  /// No description provided for @healingGateDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bondy gợi ý bạn dành 2 phút check-in cảm xúc hôm nay trước khi khám phá.'**
  String get healingGateDesc;

  /// No description provided for @checkInNow.
  ///
  /// In vi, this message translates to:
  /// **'Check-in ngay'**
  String get checkInNow;

  /// No description provided for @later.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get later;

  /// No description provided for @compatibilityReceiptTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tại sao 2 bạn match?'**
  String get compatibilityReceiptTitle;

  /// No description provided for @openChat.
  ///
  /// In vi, this message translates to:
  /// **'Mở chat'**
  String get openChat;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
