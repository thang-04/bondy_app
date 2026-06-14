class SafetyCheckResult {
  final int score;
  final List<String> matchedPatterns;
  final bool shouldWarn;

  SafetyCheckResult({
    required this.score,
    required this.matchedPatterns,
    required this.shouldWarn,
  });
}
