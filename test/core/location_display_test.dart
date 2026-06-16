import 'package:bondy/core/location_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatLocationLabel', () {
    test('combines distance and dynamic city', () {
      expect(
        formatLocationLabel(distanceKm: 6.25, city: 'Ha Dong, Ha Noi'),
        'C\u00e1ch b\u1ea1n 6.3 km \u2022 Ha Dong, Ha Noi',
      );
    });

    test('uses city only when distance is unavailable', () {
      expect(
        formatLocationLabel(distanceKm: null, city: 'Thu Duc, Ho Chi Minh'),
        'Thu Duc, Ho Chi Minh',
      );
    });

    test('does not expose coordinate strings as city names', () {
      expect(
        formatLocationLabel(distanceKm: null, city: '21.027800, 105.834200'),
        isNull,
      );
      expect(
        formatLocationLabel(distanceKm: 3, city: '21.027800, 105.834200'),
        'C\u00e1ch b\u1ea1n 3 km',
      );
    });

    test('renders very small distance as under one kilometer', () {
      expect(
        formatLocationLabel(distanceKm: 0, city: 'Quan 1, Ho Chi Minh'),
        'C\u00e1ch b\u1ea1n <1 km \u2022 Quan 1, Ho Chi Minh',
      );
    });
  });

  group('buildReadableLocationName', () {
    test('prefers district and city level fields', () {
      expect(
        buildReadableLocationName(
          street: '12 Example Street',
          subAdministrativeArea: 'Ha Dong',
          administrativeArea: 'Ha Noi',
        ),
        'Ha Dong, Ha Noi',
      );
    });

    test('returns null for coordinate-like manual values', () {
      expect(normalizeReadableLocation('21.027800, 105.834200'), isNull);
    });
  });
}
