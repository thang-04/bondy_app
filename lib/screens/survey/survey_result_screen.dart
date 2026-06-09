import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/healing/healing_navigation.dart';
import '../../services/healing/healing_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';

class SurveyResultScreen extends StatefulWidget {
  const SurveyResultScreen({super.key});

  @override
  State<SurveyResultScreen> createState() => _SurveyResultScreenState();
}

class _SurveyResultScreenState extends State<SurveyResultScreen> {
  final HealingService _healingService = HealingService();
  bool _didPrompt = false;
  String? _finalModeCode;

  void _navigateToDeepMatchSetup(String targetRoute, [Map<String, dynamic>? targetArgs]) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/deep-match/setup',
      (_) => false,
      arguments: {
        'targetRoute': targetRoute,
        if (targetArgs != null) 'targetArguments': targetArgs,
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrompt) return;
    _didPrompt = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _finalModeCode = args['finalModeCode']?.toString();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _showPlanPrompt());
  }

  bool get _needsHealing =>
      _finalModeCode == null || _finalModeCode!.toLowerCase() == 'healer';

  Future<void> _showPlanPrompt() async {
    if (_needsHealing) {
      await _showHealingPlanPrompt();
    } else {
      await _showMatchingPrompt();
    }
  }

  Future<void> _showHealingPlanPrompt() async {
    try {
      await _healingService.fetchEntryState(entry: 'ONBOARDING');
    } catch (_) {
      // Healing remains usable even if the recommendation request fails.
    }
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bạn muốn theo lộ trình chữa lành này chứ?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn có thể bắt đầu ngay, xem trước trước khi quyết định, hoặc để sau.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                 BondyButton(
                  text: 'Bắt đầu ngay',
                  onPressed: () async {
                    await _healingService.startRecommendedPlan();
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    if (!mounted) return;
                    _navigateToDeepMatchSetup(healingPlanRoute);
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _navigateToDeepMatchSetup(
                      healingPlanRoute,
                      const {'preview': true},
                    );
                  },
                  child: const Text('Xem trước'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _navigateToDeepMatchSetup('/home/healing');
                  },
                  child: const Text('Để sau'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMatchingPrompt() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('💚', style: TextStyle(fontSize: 32), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Bạn đã sẵn sàng kết nối!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bondy sẽ gợi ý những người phù hợp với hành trình của bạn.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                 BondyButton(
                  text: 'Khám phá ngay',
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _navigateToDeepMatchSetup('/discover');
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _navigateToDeepMatchSetup('/home/healing');
                  },
                  child: const Text('Xem Content Hub trước'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: BondyColors.background,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: BondyColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: BondyColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Cảm ơn bạn đã chia sẻ!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bondy đã hiểu thêm về bạn.\nĐây là lộ trình chữa lành dành riêng cho bạn.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('🌿', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        'Lộ trình: Chữa lành & Kết nối',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: BondyColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPathItem(
                        Icons.self_improvement,
                        'Tuần 1-2',
                        'Chữa lành nội tâm',
                      ),
                      _buildPathItem(
                        Icons.people_outline,
                        'Tuần 3-4',
                        'Kết nối nhẹ nhàng',
                      ),
                      _buildPathItem(
                        Icons.favorite_outline,
                        'Tuần 5+',
                        'Sẵn sàng mở lòng',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                 BondyButton(
                  text: 'Vào Healing',
                  onPressed: () {
                    _navigateToDeepMatchSetup('/home/healing');
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildPathItem(IconData icon, String week, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BondyColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: BondyColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                week,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: BondyColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: BondyColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
