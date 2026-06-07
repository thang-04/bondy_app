import 'package:bondy/screens/home/main_shell_screen.dart';
import 'package:bondy/services/relationship_service.dart';
import 'package:bondy/viewmodels/relationship/relationship_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeRelationshipService extends RelationshipService {
  @override
  Future<RelationshipDashboard> getDashboard() async {
    return RelationshipDashboard(
      hasRelationship: true,
      relationshipId: 'relationship-1',
      partnerName: 'An',
    );
  }
}

void main() {
  testWidgets('replaces the normal home when a relationship becomes active', (
    tester,
  ) async {
    final viewModel = RelationshipViewModel(
      service: _FakeRelationshipService(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(
          home: RelationshipModeHome(
            standardHome: Text('HOME THƯỜNG'),
            relationshipHome: Text('CỦA CHÚNG MÌNH'),
          ),
        ),
      ),
    );

    expect(find.text('HOME THƯỜNG'), findsOneWidget);

    await viewModel.loadDashboard();
    await tester.pump();

    expect(find.text('CỦA CHÚNG MÌNH'), findsOneWidget);
    expect(find.text('HOME THƯỜNG'), findsNothing);
  });
}
