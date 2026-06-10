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
  bool _isSaving = false;

  void _navigateToRoute(String targetRoute, [Map<String, dynamic>? targetArgs]) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      targetRoute,
      (_) => false,
      arguments: targetArgs,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrompt) return;
    _didPrompt = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      setState(() {
        _finalModeCode = args['finalModeCode']?.toString();
      });
    }
  }

  bool get _needsHealing =>
      _finalModeCode == null || _finalModeCode!.toLowerCase() == 'healer';

  Future<void> _startHealing() async {
    setState(() => _isSaving = true);
    try {
      await _healingService.startRecommendedPlan();
      if (!mounted) return;
      _navigateToRoute(healingPlanRoute);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi bắt đầu lộ trình: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsHealing = _needsHealing;

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
                    color: needsHealing ? BondyColors.primary : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (needsHealing ? BondyColors.primary : const Color(0xFF10B981)).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    needsHealing ? Icons.favorite : Icons.people_alt,
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
                  needsHealing
                      ? 'Bondy đã hiểu thêm về bạn.\nĐây là lộ trình chữa lành dành riêng cho bạn.'
                      : 'Bondy đã hiểu thêm về bạn.\nBạn đã sẵn sàng để khám phá những kết nối mới.',
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
                    borderRadius: BorderRadius.circular(16),
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
                      Text(
                        needsHealing ? '🌿' : '🧩',
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        needsHealing
                            ? 'Lộ trình: Chữa lành & Kết nối'
                            : 'Lộ trình: Kết nối & Chia sẻ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: BondyColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (needsHealing) ...[
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
                      ] else ...[
                        _buildPathItem(
                          Icons.radar,
                          'Tuần 1-2',
                          'Tìm bạn tương hợp',
                          color: const Color(0xFF10B981),
                          bgColor: const Color(0xFFD1FAE5),
                        ),
                        _buildPathItem(
                          Icons.chat_bubble_outline_rounded,
                          'Tuần 3-4',
                          'Trò chuyện sâu sắc',
                          color: const Color(0xFF10B981),
                          bgColor: const Color(0xFFD1FAE5),
                        ),
                        _buildPathItem(
                          Icons.diversity_3_outlined,
                          'Tuần 5+',
                          'Xây dựng gắn kết',
                          color: const Color(0xFF10B981),
                          bgColor: const Color(0xFFD1FAE5),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                if (needsHealing) ...[
                  BondyButton(
                    text: 'Bắt đầu ngay',
                    isLoading: _isSaving,
                    onPressed: _startHealing,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: BondyColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _navigateToRoute(
                          healingPlanRoute,
                          const {'preview': true},
                        );
                      },
                      child: Text(
                        'Xem trước',
                        style: GoogleFonts.plusJakartaSans(
                          color: BondyColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      _navigateToRoute('/home/healing');
                    },
                    child: Text(
                      'Để sau',
                      style: GoogleFonts.plusJakartaSans(
                        color: BondyColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  BondyButton(
                    text: 'Khám phá ngay',
                    onPressed: () {
                      _navigateToRoute('/discover');
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _navigateToRoute('/home/healing');
                      },
                      child: Text(
                        'Xem Content Hub trước',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildPathItem(
    IconData icon,
    String week,
    String label, {
    Color? color,
    Color? bgColor,
  }) {
    final primaryColor = color ?? BondyColors.primary;
    final primaryBgColor = bgColor ?? BondyColors.primaryLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                week,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: primaryColor,
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
