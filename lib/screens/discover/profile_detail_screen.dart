import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back_ios_new,
                    size: 16, color: BondyColors.textPrimary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: BondyColors.primaryLight,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    Text('🌸', style: TextStyle(fontSize: 80)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Minh Anh, 25',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: BondyColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✅ Đã xác thực',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: BondyColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 Hà Nội • 🌿 Đang chữa lành',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: BondyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Match compatibility
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: BondyColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite,
                            color: BondyColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '85% đồng điệu cảm xúc',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: BondyColors.primary,
                              ),
                            ),
                            Text(
                              'Dựa trên khảo sát tâm lý',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: BondyColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // About
                  Text(
                    'Về tôi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tôi tin rằng mọi tổn thương đều cần thời gian để chữa lành. Đang tìm kiếm sự đồng điệu trong tâm hồn hơn là vẻ bề ngoài.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: BondyColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Interests
                  Text(
                    'Sở thích',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag('🎵 Âm nhạc'),
                      _buildTag('📖 Đọc sách'),
                      _buildTag('🧘 Thiền'),
                      _buildTag('☕ Cà phê'),
                      _buildTag('🌿 Thiên nhiên'),
                      _buildTag('✍️ Viết lách'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Emotional profile
                  Text(
                    'Hồ sơ cảm xúc',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEmotionRow('Giao tiếp', 'Nhẹ nhàng & tinh tế'),
                  _buildEmotionRow('Tình trạng', 'Mới chia tay'),
                  _buildEmotionRow('Tìm kiếm', 'Chữa lành & kết bạn'),
                  const SizedBox(height: 32),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Bỏ qua'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Kết nối'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: BondyColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmotionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: BondyColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
