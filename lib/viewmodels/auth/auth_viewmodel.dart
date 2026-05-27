import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel({AuthService? authService})
    : _authService = authService ?? AuthService();

  bool isValid = false;
  bool isLoading = false;
  String? errorMessage;
  String? devOtp;
  String? devToken;
  bool isPasswordReset = false;

  void validateEmail(String email) {
    isValid = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);
    notifyListeners();
  }

  void validateLogin(String email, String password) {
    isValid =
        RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email) &&
        password.length >= 6;
    notifyListeners();
  }

  void validateRegister(String email, String password, String? name) {
    isValid =
        RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email) &&
        password.length >= 6;
    notifyListeners();
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
      errorMessage = error.toString();
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
      } else {
        await _navigateAfterAuth(context);
      }
    } catch (error) {
      errorMessage = error.toString();
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
      errorMessage = error.toString();
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
      errorMessage = error.toString();
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
      errorMessage = error.toString();
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
      errorMessage = error.toString();
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
      Navigator.of(context).pushNamed('/reset-password', arguments: email);
    } catch (error) {
      errorMessage = error.toString();
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
      errorMessage = error.toString();
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
      errorMessage = error.toString();
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
