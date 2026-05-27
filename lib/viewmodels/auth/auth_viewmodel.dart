import 'package:flutter/material.dart';

import '../../core/bondy_error_mapper.dart';
import '../../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  static const int minimumAge = 18;

  final AuthService _authService;

  AuthViewModel({AuthService? authService})
    : _authService = authService ?? AuthService();

  bool isValid = false;
  bool isLoading = false;
  String? errorMessage;
  String? devOtp;
  String? devToken;
  bool isPasswordReset = false;

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');

  /// F-05: registration requires a slightly stronger password — at least 8
  /// characters with both a letter and a digit. Login keeps the 6-char floor
  /// so users with older passwords can still sign in.
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    final hasLetter = password.contains(RegExp(r'[A-Za-z]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    return hasLetter && hasDigit;
  }

  void validateEmail(String email) {
    isValid = _emailRegex.hasMatch(email);
    notifyListeners();
  }

  void validateLogin(String email, String password) {
    isValid = _emailRegex.hasMatch(email) && password.length >= 6;
    notifyListeners();
  }

  void validateRegister(String email, String password, String? name) {
    isValid = _emailRegex.hasMatch(email) && isStrongPassword(password);
    notifyListeners();
  }

  String? validateBirthDate(DateTime? birthDate) {
    if (birthDate == null) {
      return 'Vui lòng nhập ngày sinh';
    }
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    if (age < minimumAge) {
      return 'Bạn phải từ $minimumAge tuổi trở lên để sử dụng ứng dụng';
    }
    if (age > 120) {
      return 'Ngày sinh không hợp lệ';
    }
    return null;
  }

  static bool isUnderage(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age < minimumAge;
  }

  Future<void> sendOtpAndNavigate(
    BuildContext context,
    String email, {
    String flow = 'signup',
  }) async {
    isLoading = true;
    errorMessage = null;
    devOtp = null;
    notifyListeners();

    try {
      final result = await _authService.sendOtp(email);
      devOtp = result.devOtp;
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushNamed('/otp', arguments: {'email': email, 'flow': flow});
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Không thể gửi OTP')),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtpAndNavigate(
    BuildContext context,
    String email,
    String otp,
    String flow,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyOtp(email: email, otp: otp);
      if (!context.mounted) return;
      if (flow == 'signup') {
        Navigator.of(
          context,
        ).pushReplacementNamed('/register', arguments: email);
      } else if (flow == 'password_reset') {
        // Don't navigate - VerifyOtpScreen will handle navigation
        return;
      } else {
        await _navigateAfterAuth(context);
      }
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Mã OTP không hợp lệ')),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendOtp(
    BuildContext context, {
    required String email,
    required String flow,
    String? password,
  }) async {
    isLoading = true;
    errorMessage = null;
    devOtp = null;
    notifyListeners();

    try {
      final isLoginFlow = flow == 'login';
      if (isLoginFlow && (password == null || password.isEmpty)) {
        throw const AuthServiceException(
          'Vui lòng nhập lại mật khẩu để gửi lại mã OTP đăng nhập',
        );
      }

      final result = isLoginFlow
          ? await _authService.requestLoginOtp(
              email: email,
              password: password!,
            )
          : await _authService.sendOtp(email);
      devOtp = result.devOtp;
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
      return true;
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Không thể gửi lại OTP')),
        );
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginAndNavigate(
    BuildContext context,
    String email,
    String password,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email: email, password: password);
      if (!context.mounted) return;
      await _navigateAfterAuth(context);
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Đăng nhập thất bại')),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPasswordAndNavigate(
    BuildContext context,
    String password,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.setPassword(password: password);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed('/profile-setup');
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Tạo mật khẩu thất bại')),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyEmailAndNavigate(
    BuildContext context,
    String token,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyEmail(token: token);
      if (!context.mounted) return;
      await _navigateAfterAuth(context);
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Xác minh email thất bại')),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPasswordAndNavigate(
    BuildContext context,
    String email,
  ) async {
    isLoading = true;
    errorMessage = null;
    devToken = null;
    notifyListeners();

    try {
      devToken = await _authService.forgotPassword(email: email);
      if (!context.mounted) return;
      Navigator.of(context).pushNamed('/verify-otp', arguments: email);
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Không thể yêu cầu đặt lại mật khẩu'),
          ),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setPasswordEmailAndNavigate(
    BuildContext context,
    String email,
    String password,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.setPasswordEmail(email: email, password: password);
      isPasswordReset = true;
      return true;
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Đặt lại mật khẩu thất bại')),
        );
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPasswordAndNavigate(
    BuildContext context,
    String token,
    String password,
  ) async {
    isLoading = true;
    errorMessage = null;
    isPasswordReset = false;
    notifyListeners();

    try {
      await _authService.resetPassword(token: token, password: password);
      isPasswordReset = true;
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/login', (route) => route.isFirst);
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Đặt lại mật khẩu thất bại')),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(
    BuildContext context,
    String currentPassword,
    String newPassword,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công')));
      Navigator.of(context).pop();
    } catch (error) {
      errorMessage = BondyErrorMapper.message(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Đổi mật khẩu thất bại')),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> skipEmailVerification(BuildContext context) async {
    await _navigateAfterAuth(context);
  }

  Future<void> _navigateAfterAuth(BuildContext context) async {
    try {
      final userData = await _authService.getCurrentUser();
      if (!context.mounted) return;

      // Check email verification status
      final emailVerified = userData['emailVerified'] != null;

      if (!emailVerified) {
        // Redirect to email verification screen
        Navigator.of(context).pushReplacementNamed('/verify-email');
        return;
      }

      final profile = userData['profile'];
      final hasCompletedProfile =
          profile is Map<String, dynamic> &&
          profile['fullName'] != null &&
          profile['gender'] != null &&
          profile['birthDate'] != null;
      if (hasCompletedProfile) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/profile-setup');
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/profile-setup');
      }
    }
  }
}
