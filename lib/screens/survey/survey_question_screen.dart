import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/survey_option_card.dart';
import '../../viewmodels/survey/survey_viewmodel.dart';
import '../../models/survey/survey_question_model.dart';

/// Màn hình Động cho tất cả các câu hỏi khảo sát.
/// Lắng nghe trạng thái từ SurveyViewModel.
class SurveyQuestionScreen extends StatefulWidget {
  const SurveyQuestionScreen({super.key});

  @override
  State<SurveyQuestionScreen> createState() => _SurveyQuestionScreenState();
}

class _SurveyQuestionScreenState extends State<SurveyQuestionScreen> {
  double _localSliderValue = 5;

  @override
  Widget build(BuildContext context) {
    // Lắng nghe ViewModel
    final viewModel = context.watch<SurveyViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BondyColors.primary),
          ),
        ),
      );
    }

    if (viewModel.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BondyErrorBanner(message: viewModel.errorMessage!),
                const SizedBox(height: 24),
                BondyButton(
                  text: 'Quay lại',
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = viewModel.currentQuestion;
    if (currentQuestion == null) {
      return const SizedBox();
    }

    final totalQuestions = viewModel.questions.length;
    final progress = (viewModel.currentIndex + 1) / totalQuestions;
    
    // Đồng bộ giá trị slider nếu có lưu từ trước
    if (currentQuestion.isSlider && viewModel.currentAnswer != null) {
      _localSliderValue = (viewModel.currentAnswer as num).toDouble();
    } else if (currentQuestion.isSlider) {
      // Setup default slider value
      _localSliderValue = ((currentQuestion.maxValue ?? 10) + (currentQuestion.minValue ?? 0)) / 2;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (viewModel.currentIndex > 0) {
              viewModel.previousQuestion(); // Quay lại câu trc đó mà k back ra ngoài
            } else {
              Navigator.pop(context); // Trở về màn trước (Intro)
            }
          },
        ),
        title: Text('Câu ${viewModel.currentIndex + 1}/$totalQuestions'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: BondyColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    BondyColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Question
              Text(
                currentQuestion.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentQuestion.subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Dynamic Question Body rendered via switch case
              Expanded(
                child: _buildQuestionBody(currentQuestion, viewModel),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!currentQuestion.isRequired)
                    TextButton(
                      onPressed: () {
                        // Skip question
                        context.read<SurveyViewModel>().nextQuestion(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        minimumSize: const Size(0, 56), // match height
                      ),
                      child: Text(
                        'Bỏ qua',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: BondyColors.textHint,
                        ),
                      ),
                    )
                  else
                    const SizedBox(), // Chỗ trống để đẩy nút Tiếp theo sang phải
                  ElevatedButton(
                    onPressed: (viewModel.currentAnswer != null) || currentQuestion.isSlider || viewModel.isSubmitting
                        ? () {
                            if (viewModel.isSubmitting) return;
                            if (currentQuestion.isSlider) {
                              context.read<SurveyViewModel>().saveAnswer(_localSliderValue);
                            }
                            context.read<SurveyViewModel>().nextQuestion(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BondyColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 56), // fixed height, flexible width
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (viewModel.isSubmitting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        else ...[
                          Text(
                            viewModel.isLastQuestion ? 'Hoàn tất' : 'Tiếp theo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!viewModel.isLastQuestion)
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionBody(SurveyQuestion question, SurveyViewModel viewModel) {
    switch (question.type.toUpperCase()) {
      case 'CHOICE':
      case 'SINGLE_CHOICE':
      case 'MULTIPLE_CHOICE':
      case 'YES_NO':
      case 'BOOLEAN':
        if (question.isMultipleChoice || question.type.toUpperCase() == 'MULTIPLE_CHOICE') {
          return _buildMultipleChoice(question, viewModel);
        }
        return _buildSingleChoice(question, viewModel);
      case 'SLIDER':
      case 'SCALE':
        return _buildSlider(viewModel);
      case 'TEXT':
      case 'TEXTAREA':
        return _buildTextInput(question, viewModel);
      case 'DATE':
        return _buildDatePicker(question, viewModel);
      case 'RATING':
        return _buildRating(question, viewModel);
      default:
        return _buildFallback(question);
    }
  }

  Widget _buildSingleChoice(SurveyQuestion question, SurveyViewModel viewModel) {
    return ListView.separated(
      itemCount: question.options.length,
      separatorBuilder: (context, sepIndex) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = viewModel.isOptionSelected(option.id);
        return SurveyOptionCard(
          title: option.title,
          subtitle: option.subtitle,
          emoji: option.emoji,
          isSelected: isSelected,
          onTap: () => viewModel.saveAnswer(option.id),
        );
      },
    );
  }

  Widget _buildMultipleChoice(SurveyQuestion question, SurveyViewModel viewModel) {
    return ListView.separated(
      itemCount: question.options.length,
      separatorBuilder: (context, sepIndex) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = viewModel.isOptionSelected(option.id);
        return SurveyOptionCard(
          title: option.title,
          subtitle: option.subtitle,
          emoji: option.emoji,
          isSelected: isSelected,
          onTap: () => viewModel.toggleMultipleChoiceAnswer(option.id),
        );
      },
    );
  }

  Widget _buildTextInput(SurveyQuestion question, SurveyViewModel viewModel) {
    return Column(
      children: [
        TextFormField(
          key: ValueKey(question.id),
          initialValue: viewModel.currentAnswer as String? ?? '',
          maxLines: question.type.toUpperCase() == 'TEXTAREA' ? 4 : 1,
          onChanged: (val) {
            viewModel.saveAnswer(val.trim().isEmpty ? null : val);
          },
          decoration: InputDecoration(
            hintText: 'Nhập câu trả lời của bạn...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BondyColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BondyColors.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: BondyColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(SurveyQuestion question, SurveyViewModel viewModel) {
    final current = viewModel.currentAnswer is String
        ? DateTime.tryParse(viewModel.currentAnswer as String)
        : null;
    return Column(
      children: [
        ListTile(
          title: Text(
            current != null
                ? '${current.day}/${current.month}/${current.year}'
                : 'Chọn ngày',
            style: GoogleFonts.plusJakartaSans(fontSize: 16),
          ),
          trailing: const Icon(Icons.calendar_today, color: BondyColors.primary),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: current ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              viewModel.saveAnswer(picked.toIso8601String());
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  Widget _buildRating(SurveyQuestion question, SurveyViewModel viewModel) {
    final max = (question.maxValue ?? 5).toInt();
    final current = (viewModel.currentAnswer as num?)?.toInt() ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(max, (index) {
        final star = index + 1;
        final filled = star <= current;
        return IconButton(
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: BondyColors.primary,
            size: 36,
          ),
          onPressed: () {
            viewModel.saveAnswer(star);
            setState(() {});
          },
        );
      }),
    );
  }

  Widget _buildFallback(SurveyQuestion question) {
    return Center(
      child: Text(
        "Chưa hỗ trợ giao diện cho loại câu hỏi:\n${question.type}",
        style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSlider(SurveyViewModel viewModel) {
    double minVal = viewModel.currentQuestion?.minValue?.toDouble() ?? 0.0;
    double maxVal = viewModel.currentQuestion?.maxValue?.toDouble() ?? 10.0;
    int divisions = (maxVal - minVal).round();
    if (divisions <= 0) divisions = 10;
    
    // Đảm bảo value luôn nằm trong khoảng min..max để tránh lỗi assertion của Flutter
    double safeValue = _localSliderValue.clamp(minVal, maxVal);

    return Column(
      children: [
        const Spacer(),
        Text(
          '${safeValue.round()}/${maxVal.round()}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: BondyColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getSliderLabel(safeValue, minVal, maxVal),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: BondyColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: BondyColors.primary,
            inactiveTrackColor: BondyColors.divider,
            thumbColor: BondyColors.primary,
            overlayColor: BondyColors.primary.withValues(alpha: 0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: safeValue,
            min: minVal,
            max: maxVal,
            divisions: divisions,
            onChanged: (value) {
              setState(() => _localSliderValue = value);
              viewModel.saveAnswer(value);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chưa sẵn sàng',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: BondyColors.textHint,
              ),
            ),
            Text(
              'Rất sẵn sàng',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: BondyColors.textHint,
              ),
            ),
          ],
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  String _getSliderLabel(double value, double min, double max) {
    if (max == min) return 'Sẵn sàng mở lòng';
    double percent = (value - min) / (max - min);
    if (percent <= 0.3) return 'Cần thêm thời gian';
    if (percent <= 0.6) return 'Đang cân nhắc';
    return 'Sẵn sàng mở lòng';
  }
}
