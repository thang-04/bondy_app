import 'package:bondy/models/discover/discover_profile_model.dart';
import 'package:bondy/screens/discover/widgets/discover_filters_sheet.dart';
import 'package:bondy/services/discover_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDiscoverService extends DiscoverService {
  DiscoverFilters? savedFilters;

  @override
  Future<void> saveFilters(DiscoverFilters filters) async {
    savedFilters = filters;
  }
}

void main() {
  testWidgets('lets users choose target genders in swipe filters', (
    tester,
  ) async {
    final service = FakeDiscoverService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DiscoverFiltersSheet(service: service)),
      ),
    );

    await tester.tap(find.byKey(const Key('discover_filter_gender_FEMALE')));
    await tester.ensureVisible(
      find.byKey(const Key('discover_filter_apply_button')),
    );
    await tester.tap(find.byKey(const Key('discover_filter_apply_button')));
    await tester.pumpAndSettle();

    expect(service.savedFilters?.genders, ['FEMALE']);
  });
}
