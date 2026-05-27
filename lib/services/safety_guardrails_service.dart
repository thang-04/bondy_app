import 'safety_check_result.dart';

class SafetyGuardrailsService {
  static const int _warningThreshold = 3;
  static const int _maxInputLength = 1000;

  static final List<_RiskPattern> _criticalPatterns = [
    _RiskPattern(r'\btự tử\b|\btự sát\b|\btự hại\b|\btự gây thương tích\b', 3),
    _RiskPattern(r"\bkill myself\b|\bend my life\b|\bdon't want to live\b", 3),
    _RiskPattern(r'\bkhủng hoảng\b|\bcub bản thân\b|\bmất kiểm soát\b', 3),
  ];

  static final List<_RiskPattern> _intentModifiers = [
    _RiskPattern(r'\bmuốn\b|\bđịnh\b|\bsẽ\b|\bđang muốn\b', 2),
    _RiskPattern(r'\bnay\b|\bbây giờ\b|\blập tức\b', 2),
  ];

  SafetyCheckResult check(String message) {
    // Input length validation to prevent ReDoS
    if (message.length > _maxInputLength) {
      return SafetyCheckResult(
        score: 0,
        matchedPatterns: [],
        shouldWarn: false,
      );
    }

    final matchedPatterns = <String>[];
    int criticalScore = 0;
    bool hasModifier = false;

    final lowerMessage = message.toLowerCase();

    // Check critical keywords
    for (final pattern in _criticalPatterns) {
      final matches = pattern.regex.allMatches(lowerMessage);
      if (matches.isNotEmpty) {
        matchedPatterns.addAll(matches.map((m) => m.group(0)!));
        criticalScore += pattern.weight;
      }
    }

    // Check modifiers
    for (final pattern in _intentModifiers) {
      if (pattern.regex.hasMatch(lowerMessage)) {
        hasModifier = true;
      }
    }

    // Calculate final score
    int score = criticalScore;
    if (criticalScore > 0 && hasModifier) {
      score += 2;
    }

    return SafetyCheckResult(
      score: score,
      matchedPatterns: matchedPatterns,
      shouldWarn: score >= _warningThreshold,
    );
  }
}

class _RiskPattern {
  final RegExp regex;
  final int weight;

  _RiskPattern(String pattern, this.weight) : regex = RegExp(pattern, caseSensitive: false);
}