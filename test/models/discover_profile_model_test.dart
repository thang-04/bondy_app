import 'package:bondy/models/discover/discover_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats profile location from distance and dynamic city', () {
    final profile = DiscoverProfile.fromJson({
      'userId': 'candidate-id',
      'name': 'Mai',
      'age': 25,
      'city': 'Dong Da, Ha Noi',
      'distanceKm': 4.75,
      'bio': '',
      'photos': const [],
    });

    expect(
      profile.distance,
      'C\u00e1ch b\u1ea1n 4.8 km \u2022 Dong Da, Ha Noi',
    );
  });

  test('hides coordinate city when distance is missing', () {
    final profile = DiscoverProfile.fromJson({
      'userId': 'candidate-id',
      'name': 'Mai',
      'age': 25,
      'city': '21.027800, 105.834200',
      'bio': '',
      'photos': const [],
    });

    expect(profile.distance, '');
  });
}
