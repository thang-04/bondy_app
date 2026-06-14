import 'package:bondy/models/discover/discover_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes canonical gender and goal filters for discover query', () {
    const filters = DiscoverFilters(
      genders: ['FEMALE', 'NON_BINARY'],
      goals: ['LONG_TERM'],
      minAge: 24,
      maxAge: 36,
      maxDistance: 25,
      minCompatibility: 70,
    );

    expect(filters.toQueryParams(), {
      'genders': 'FEMALE,NON_BINARY',
      'goals': 'LONG_TERM',
      'ageMin': 24,
      'ageMax': 36,
      'distanceKm': 25,
      'minCompatibility': 70,
    });
  });
}
