import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AskBondyBottomSheet extends StatefulWidget {
  final Function(String message) onSubmit;

  const AskBondyBottomSheet({super.key, required this.onSubmit});

  @override
  State<AskBondyBottomSheet> createState() => _AskBondyBottomSheetState();
}

class _AskBondyBottomSheetState extends State<AskBondyBottomSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pull indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: BondyColors.primaryGradient,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bondy AI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: BondyColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'LẮNG NGHE & THẤU HIỂU',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: BondyColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tilted Welcome AI Card
          Transform.rotate(
            angle: 0.03, // Tilted approx 2 degrees
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: BondyColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: BondyColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bondy lắng nghe bạn...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Một không gian an toàn để chia sẻ cảm xúc và tìm lời khuyên cho trái tim.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Prompts List
          Text(
            'GỢI Ý TRÒ CHUYỆN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildPromptButton(
            icon: Icons.forum_outlined,
            text: 'Làm sao để mở đầu câu chuyện?',
            color: const Color(0xFFF0F7FF),
            onTap: () => widget.onSubmit('Làm sao để mở đầu câu chuyện?'),
          ),
          _buildPromptButton(
            icon: Icons.sentiment_dissatisfied_outlined,
            text: 'Hôm nay mình thấy hơi mệt mỏi',
            color: const Color(0xFFF5F3FF),
            onTap: () => widget.onSubmit('Hôm nay mình thấy hơi mệt mỏi'),
          ),
          _buildPromptButton(
            icon: Icons.track_changes,
            text: 'Tư vấn về mục tiêu yêu đương',
            color: const Color(0xFFFFF1F2),
            onTap: () => widget.onSubmit('Tư vấn về mục tiêu yêu đương'),
          ),
          const SizedBox(height: 20),
          // Chat input row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi của bạn...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  final txt = _controller.text.trim();
                  if (txt.isNotEmpty) widget.onSubmit(txt);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: BondyColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.green, size: 14),
              const SizedBox(width: 4),
              Text(
                'Cuộc trò chuyện của bạn luôn được bảo mật',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: BondyColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 12),
            ],
          ),
        ),
      ),
    );
  }
}
