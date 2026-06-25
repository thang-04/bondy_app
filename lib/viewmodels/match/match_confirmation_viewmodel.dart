import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/api_client.dart';
import '../../services/analytics_service.dart';

enum MatchConfirmationStatus { pending, confirmed, expired }

class MatchConfirmationViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final String matchId;

  MatchConfirmationViewModel({required this.matchId, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  MatchConfirmationStatus _status = MatchConfirmationStatus.pending;
  String? _chatId;
  String? _otherUserId;
  String? _otherUserName;
  String? _otherUserPhoto;
  DateTime? _expiresAt;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  bool _disposed = false;

  MatchConfirmationStatus get status => _status;
  String? get chatId => _chatId;
  String? get otherUserId => _otherUserId;
  String? get otherUserName => _otherUserName;
  String? get otherUserPhoto => _otherUserPhoto;
  DateTime? get expiresAt => _expiresAt;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Duration get remainingTime => _remainingTime;

  String get formattedRemainingTime {
    final hours = _remainingTime.inHours.toString().padLeft(2, '0');
    final minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> loadMatchStatus() async {
    _isLoading = true;
    _errorMessage = null;
    if (!_disposed) notifyListeners();

    try {
      final response = await _apiClient.get(
        '/matches/$matchId',
        authenticated: true,
      );
      final data = response['data'] as Map<String, dynamic>;

      _applyMatchData(data);
    } catch (_) {
      _errorMessage = 'Không thể tải trạng thái kết nối. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> confirmMatch() async {
    _isLoading = true;
    _errorMessage = null;
    if (!_disposed) notifyListeners();

    try {
      final response = await _apiClient.post(
        '/matches/$matchId/confirm',
        authenticated: true,
      );
      final data = response['data'] as Map<String, dynamic>;

      _status = _parseStatus(data['status'] as String? ?? 'PENDING');
      _chatId = data['chatId'] as String?;
      if (_status == MatchConfirmationStatus.confirmed) {
        analytics.matchConfirmed(matchId);
        _countdownTimer?.cancel();
        _remainingTime = Duration.zero;
      }
    } catch (_) {
      _errorMessage = 'Không thể xác nhận kết nối. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _applyMatchData(Map<String, dynamic> data) {
    _status = _parseStatus(data['status'] as String? ?? 'PENDING');
    _chatId = data['chatId'] as String?;
    _parseOtherUser(data['otherUser']);

    if (data['expiresAt'] != null &&
        _status == MatchConfirmationStatus.pending) {
      _expiresAt = DateTime.parse(data['expiresAt'] as String);
      _startCountdown();
    } else {
      _expiresAt = null;
      _remainingTime = Duration.zero;
      _countdownTimer?.cancel();
    }
  }

  MatchConfirmationStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return MatchConfirmationStatus.confirmed;
      case 'EXPIRED':
      case 'UNMATCHED':
      case 'BLOCKED':
        return MatchConfirmationStatus.expired;
      default:
        return MatchConfirmationStatus.pending;
    }
  }

  void _parseOtherUser(dynamic value) {
    if (value is! Map<String, dynamic>) return;

    _otherUserId = value['id'] as String?;
    final firstName = value['firstName'] as String? ?? '';
    final lastName = value['lastName'] as String? ?? '';
    final displayName = '$firstName $lastName'.trim();
    _otherUserName = displayName.isEmpty ? null : displayName;
    _otherUserPhoto = value['photo'] as String?;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateRemainingTime();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) {
        _countdownTimer?.cancel();
        return;
      }
      _updateRemainingTime();
      if (_remainingTime <= Duration.zero) {
        _countdownTimer?.cancel();
        _status = MatchConfirmationStatus.expired;
      }
      notifyListeners();
    });
  }

  void _updateRemainingTime() {
    if (_expiresAt != null) {
      final now = DateTime.now();
      _remainingTime = _expiresAt!.difference(now);
      if (_remainingTime.isNegative) {
        _remainingTime = Duration.zero;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _countdownTimer?.cancel();
    super.dispose();
  }
}
