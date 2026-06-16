final RegExp _coordinateLikePattern = RegExp(
  r'^\s*[+-]?\d{1,3}(?:\.\d+)?\s*,\s*[+-]?\d{1,3}(?:\.\d+)?\s*$',
);

bool isCoordinateLikeLocation(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return false;
  return _coordinateLikePattern.hasMatch(text);
}

String? normalizeReadableLocation(String? value) {
  final text = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text == null || text.isEmpty) return null;
  if (isCoordinateLikeLocation(text)) return null;
  return text;
}

String? formatLocationLabel({num? distanceKm, String? city}) {
  final readableCity = normalizeReadableLocation(city);
  final distanceText = _formatDistance(distanceKm);

  if (distanceText != null && readableCity != null) {
    return '$distanceText \u2022 $readableCity';
  }
  return distanceText ?? readableCity;
}

String? buildReadableLocationName({
  String? street,
  String? subLocality,
  String? locality,
  String? subAdministrativeArea,
  String? administrativeArea,
}) {
  final parts = <String>[];
  final seen = <String>{};

  for (final raw in [
    subAdministrativeArea,
    locality,
    subLocality,
    administrativeArea,
  ]) {
    final part = normalizeReadableLocation(raw);
    if (part == null) continue;
    final key = part.toLowerCase();
    if (seen.add(key)) {
      parts.add(part);
    }
    if (parts.length == 2) break;
  }

  if (parts.isEmpty) return null;
  return parts.join(', ');
}

String? _formatDistance(num? distanceKm) {
  if (distanceKm == null || !distanceKm.isFinite || distanceKm < 0) {
    return null;
  }

  if (distanceKm < 1) {
    return 'C\u00e1ch b\u1ea1n <1 km';
  }

  final rounded = (distanceKm * 10).round() / 10;
  final text = rounded % 1 == 0
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(1);
  return 'C\u00e1ch b\u1ea1n $text km';
}
