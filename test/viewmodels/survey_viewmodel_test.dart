import 'package:bondy/models/survey/survey_question_model.dart';
import 'package:bondy/services/survey_service.dart';
import 'package:bondy/viewmodels/survey/survey_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigates to survey result after submitting last question', (
    tester,
  ) async {
    final surveyService = _FakeSurveyService();
    final viewModel = SurveyViewModel(surveyService: surveyService);

    await viewModel.loadSurvey('onboarding');
    viewModel.saveAnswer('option-id');

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (context) => Scaffold(
            body: TextButton(
              onPressed: () => viewModel.nextQuestion(context),
              child: const Text('complete survey'),
            ),
          ),
          '/image-upload': (context) =>
              const Scaffold(body: Text('image upload')),
          '/survey/result': (context) =>
              const Scaffold(body: Text('survey result')),
        },
      ),
    );

    await tester.tap(find.text('complete survey'));
    await tester.pumpAndSettle();

    expect(surveyService.submitCalls, 1);
    expect(find.text('survey result'), findsOneWidget);
    expect(find.text('image upload'), findsNothing);
  });
}

class _FakeSurveyService extends SurveyService {
  int submitCalls = 0;

  @override
  Future<(String, List<SurveyQuestion>)> fetchActiveSurvey({
    required String surveyType,
  }) async {
    return (
      'survey-id',
      const [
        SurveyQuestion(
          id: 'question-id',
          title: 'Goal',
          subtitle: '',
          type: 'SINGLE_CHOICE',
          options: [
            SurveyOption(id: 'option-id', title: 'A serious relationship'),
          ],
        ),
      ],
    );
  }

  @override
  Future<(bool, String?, String?)> submitSurvey(
    String surveyId,
    Map<String, dynamic> answersMap,
    List<SurveyQuestion> questions,
  ) async {
    submitCalls++;
    return (true, null, null);
  }
}
