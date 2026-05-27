import 'package:bondy/models/discover/discover_profile_model.dart';
import 'package:bondy/services/discover_service.dart';
import 'package:bondy/viewmodels/discover/discover_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDiscoverService extends DiscoverService {
  FakeDiscoverService({
    this.profiles = const [],
    this.error,
    this.swipeError,
    this.swipeResult = const SwipeResult(matched: false),
  });

  final List<DiscoverProfile> profiles;
  final Object? error;
  final Object? swipeError;
  final SwipeResult swipeResult;
  String? lastSwipeAction;

  @override
  Future<DiscoverFetchResult> fetchProfilesFull({
    Map<String, dynamic>? filters,
  }) async {
    if (error != null) throw error!;
    return DiscoverFetchResult(profiles: profiles);
  }

  @override
  Future<void> checkLikeQuota() async {}

  @override
  Future<SwipeResult> swipe({
    required String targetUserId,
    required String action,
  }) async {
    if (swipeError != null) throw swipeError!;
    lastSwipeAction = action;
    return swipeResult;
  }
}

void main() {
  test('loads candidates into loaded state', () async {
    final service = FakeDiscoverService(
      profiles: const [
        DiscoverProfile(
          id: 'candidate-id',
          name: 'Linh',
          age: 24,
          distance: 'Ho Chi Minh',
          bio: 'Xin chao',
          tags: ['Music'],
          matchPercentage: 80,
          imageUrl: '👤',
        ),
      ],
    );
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

    final errorViewModel = DiscoverViewModel(
      service: FakeDiscoverService(swipeError: Exception('failed')),
    );
    await errorViewModel.swipe('candidate-id', 'PASS');

    expect(errorViewModel.errorMessage, isNotNull);
  });

  test(
    'stores match and chat ids when a swipe creates an instant match',
    () async {
      final service = FakeDiscoverService(
        swipeResult: const SwipeResult(
          matched: true,
          matchId: 'match-123',
          conversationId: 'chat-456',
        ),
      );
      final viewModel = DiscoverViewModel(service: service);

      final matched = await viewModel.swipe('candidate-id', 'LIKE');

      expect(matched, true);
      expect(viewModel.lastMatchId, 'match-123');
      expect(viewModel.lastConversationId, 'chat-456');
    },
  );
}
