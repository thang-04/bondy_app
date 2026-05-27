import 'package:bondy/services/auth_service.dart';
import 'package:bondy/viewmodels/home/home_viewmodel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('authenticated home loading reports error when no user is stored', () async {
    const storage = FlutterSecureStorage();
    final authService = AuthService(baseUrlOverride: 'https://api.example.com/api', storage: storage);
    final viewModel = HomeViewModel();

    await viewModel.loadAuthenticatedContent(authService: authService);

    expect(viewModel.state, isA<HomeError>());
    expect((viewModel.state as HomeError).message, contains('đăng nhập'));
  });
}
