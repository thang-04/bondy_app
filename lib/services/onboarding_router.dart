import 'package:flutter/material.dart';
import 'auth_service.dart';

class OnboardingRouter {
  static final AuthService _authService = AuthService();

  static String routeForAction(String? nextAction) {
    switch (nextAction) {
      case 'ADD_PHOTOS':
        return '/image-upload';
      case 'SET_LOCATION':
        return '/location-setup';
      case 'ADD_INTERESTS':
        return '/interests-setup';
      case 'COMPLETE_SURVEY':
        return '/survey/intro';
      case 'COMPLETE_PROFILE':
        return '/profile-setup';
      case 'SET_MATCH_PREFERENCES':
        return '/match-preferences/setup';
      case 'READY':
        return '/home';
      default:
        return '/profile-setup';
    }
  }

  /// Call GET /api/auth/me, read nextAction, navigate to the correct next step.
  /// [state] must be a [State] so we can check [State.mounted] across async gaps.
  static Future<void> navigateToNextStep(BuildContext context) async {
    try {
      final nav = Navigator.of(context);
      final user = await _authService.getCurrentUser();

      final profile = user['profile'];
      bool isDeepMatchComplete = false;
      if (profile is Map<String, dynamic>) {
        final zodiacSign = profile['zodiacSign'];
        final desiredPartnerType = profile['desiredPartnerType'];
        final freeTimeSlots = profile['freeTimeSlots'];
        if (zodiacSign != null &&
            desiredPartnerType != null &&
            freeTimeSlots is List &&
            freeTimeSlots.isNotEmpty) {
          isDeepMatchComplete = true;
        }
      }

      if (user['profileComplete'] == true) {
        if (user['surveyComplete'] != true) {
          if (!isDeepMatchComplete) {
            nav.pushNamedAndRemoveUntil(
              '/deep-match/setup',
              (r) => false,
              arguments: const {'targetRoute': '/survey/intro'},
            );
            return;
          }
          nav.pushNamedAndRemoveUntil('/survey/intro', (r) => false);
          return;
        }
        nav.pushNamedAndRemoveUntil('/home', (r) => false);
        return;
      }

      final status = user['profileCompletionStatus'];
      if (status is Map<String, dynamic>) {
        final nextAction = status['nextAction'] as String?;
        if (nextAction == 'COMPLETE_SURVEY' && !isDeepMatchComplete) {
          nav.pushNamedAndRemoveUntil(
            '/deep-match/setup',
            (r) => false,
            arguments: const {'targetRoute': '/survey/intro'},
          );
          return;
        }
        final route = routeForAction(nextAction);
        nav.pushNamedAndRemoveUntil(route, (r) => false);
        return;
      }

      nav.pushNamedAndRemoveUntil('/home', (r) => false);
    } catch (e) {
      debugPrint('OnboardingRouter error: $e');
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      }
    }
  }
}
