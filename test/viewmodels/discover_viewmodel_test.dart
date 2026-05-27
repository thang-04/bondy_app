import 'package:bondy/models/discover/discover_profile_model.dart';
import 'package:bondy/services/discover_service.dart';
import 'package:bondy/viewmodels/discover/discover_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDiscoverService extends DiscoverService {
  FakeDiscoverService({this.profiles = const [], this.error, this.swipeError});

  final List<DiscoverProfile> profiles;
  final Object? error;
  final Object? swipeError;
  String? lastSwipeAction;

  @override
  Future<List<DiscoverProfile>> fetchProfiles() async {
    if (error != null) throw error!;
    return profiles;
  }

  @override
  Future<void> swipe({required String targetUserId, required String action}) async {
    if (swipeError != null) throw swipeError!;
    lastSwipeAction = action;
  }
}

void main() {
  test('loads candidates into loaded state', () async {
    final service = FakeDiscoverService(profiles: const [
      DiscoverProfile(id: 'candidate-id', name: 'Linh', age: 24, distance: 'Ho Chi Minh', bio: 'Xin chao', tags: ['Music'], matchPercentage: 80, imageUrl: '👤'),
    ]);
    final viewModel = DiscoverViewModel(service: service);

    await viewModel.loadProfiles();

    expect(viewModel.isLoading, false);
    expect(viewModel.profiles.single.id, 'candidate-id');
    expect(viewModel.errorMessage, isNull);
  });

  test('supports empty candidate state', () async {
    final viewModel = DiscoverViewModel(service: FakeDiscoverService());

    await viewModel.loadProfiles();

    expect(viewModel.profiles, isEmpty);
    expect(viewModel.isEmpty, true);
  });

  test('records swipe success and errors', () async {
    final service = FakeDiscoverService();
    final viewModel = DiscoverViewModel(service: service);

    await viewModel.swipe('candidate-id', 'LIKE');

    expect(service.lastSwipeAction, 'LIKE');
    expect(viewModel.errorMessage, isNull);

    final errorViewModel = DiscoverViewModel(service: FakeDiscoverService(swipeError: Exception('failed')));
    await errorViewModel.swipe('candidate-id', 'PASS');

    expect(errorViewModel.errorMessage, contains('failed'));
  });
}
