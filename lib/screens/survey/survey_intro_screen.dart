import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';
import '../../viewmodels/survey/survey_viewmodel.dart';
import 'widgets/survey_intro_graphic.dart';

class SurveyIntroScreen extends StatelessWidget {
  const SurveyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Matches background-light
      body: Stack(
        children: [
          // Background Blob 1
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFE79688,
                ).withValues(alpha: 0.2), // accent/20
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE79688).withValues(alpha: 0.2),
                    blurRadius: 50,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // Background Blob 2
          Positioned(
            bottom: 40,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BondyColors.secondary.withValues(
                  alpha: 0.1,
                ), // secondary/10
                boxShadow: [
                  BoxShadow(
                    color: BondyColors.secondary.withValues(alpha: 0.1),
                    blurRadius: 50,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SurveyIntroGraphic(),
                                const SizedBox(height: 40),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: BondyColors.textPrimary,
                                      height: 1.2,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'Bondy muốn hiểu bạn đang ở ',
                                      ),
                                      TextSpan(
                                        text: 'giai đoạn nào',
                                        style: TextStyle(
                                          color: BondyColors.primary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '\ntrong chuyện tình cảm.',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Điều này giúp chúng tôi gợi ý trải nghiệm\nphù hợp – không áp đặt.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    color: BondyColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                // 3 indicator dots
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: BondyColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: BondyColors.divider,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: BondyColors.divider,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.9),
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BondyButton(
                        text: 'Bắt đầu',
                        onPressed: () async {
                          final viewModel = context.read<SurveyViewModel>();
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          await viewModel.loadSurveyWithCompletionCheck(
                            'onboarding',
                          );

                          if (viewModel.isAlreadyCompleted) {
                            // Đã hoàn thành survey, chuyển thẳng đến Home
                            navigator.pushNamedAndRemoveUntil(
                              '/home',
                              (route) => false,
                            );
                          } else if (viewModel.errorMessage != null) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(viewModel.errorMessage!)),
                            );
                          } else {
                            navigator.pushNamed('/survey/question');
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'An toàn • Riêng tư • Tôn trọng',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: BondyColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
