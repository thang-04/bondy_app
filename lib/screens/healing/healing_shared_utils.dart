String healingGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'buổi sáng';
  if (hour < 18) return 'buổi chiều';
  return 'buổi tối';
}

String readinessFromIntensity(int intensity) {
  if (intensity >= 7) return 'NOT_READY';
  if (intensity >= 4) return 'EXPLORING';
  return 'READY';
}

List<String> needsFromMood(String mood) {
  return switch (mood.toUpperCase()) {
    'ANXIOUS' || 'STRESSED' => const ['CALM_DOWN'],
    'SAD' => const ['SELF_COMPASSION'],
    'ANGRY' => const ['COOL_OFF'],
    _ => const ['REFLECTION'],
  };
}
