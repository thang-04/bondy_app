import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../healing/healing_stitch_style.dart';

/// Màn hình hướng dẫn Mời Tri kỷ (đã chuyển sang luồng in-app).
/// Không còn sử dụng mã mời — hướng dẫn user tìm nút Tri kỷ trong Chat Info.
class RelationshipInvitationScreen extends StatelessWidget {
  const RelationshipInvitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      appBar: AppBar(
        backgroundColor: HealingStitchColors.warmBackground,
        elevation: 0,
        leading: HealingIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.pop(context),
        ),
        title: Text(
          'Mời tri kỷ',
          style: healingText(size: 16, weight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Hero illustration
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF5F3), Color(0xFFFFF0F5)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('💕', style: TextStyle(fontSize: 72)),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Mời Tri kỷ qua trò chuyện',
              style: healingText(size: 22, weight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Giờ đây bạn có thể mời Tri kỷ trực tiếp từ cuộc trò chuyện — không cần mã mời!',
              style: healingText(
                size: 14,
                height: 1.6,
                color: HealingStitchColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 36),

            // Step-by-step guide
            _buildStep(
              number: '1',
              icon: Icons.chat_bubble_outline,
              title: 'Mở cuộc trò chuyện',
              description: 'Vào phần Tin nhắn, chọn người bạn muốn mời.',
            ),
            const SizedBox(height: 16),
            _buildStep(
              number: '2',
              icon: Icons.more_vert,
              title: 'Nhấn nút ⋮',
              description: 'Nhấn biểu tượng 3 chấm ở góc trên bên phải.',
            ),
            const SizedBox(height: 16),
            _buildStep(
              number: '3',
              icon: Icons.info_outline,
              title: 'Chọn "Thông tin"',
              description: 'Bạn sẽ thấy nút "Mời Tri kỷ" ở màn hình thông tin.',
            ),

            const SizedBox(height: 36),

            // CTA button
            HealingGradientButton(
              label: 'Đi tới Tin nhắn',
              icon: Icons.arrow_forward,
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home/matches',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HealingStitchColors.border),
        boxShadow: [healingSoftShadow(0.04)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: HealingStitchColors.warmGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: HealingStitchColors.coral),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: healingText(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: healingText(
                    size: 12,
                    color: HealingStitchColors.textMuted,
                    height: 1.4,
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

