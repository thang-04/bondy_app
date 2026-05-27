import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ContentHubLibraryScreen extends StatelessWidget {
  const ContentHubLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thư viện nội dung'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài viết, audio...',
                prefixIcon: const Icon(Icons.search, color: BondyColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: BondyColors.divider),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Categories
            Text(
              'Danh mục',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('Tất cả', true),
                  _buildCategoryChip('Bài viết', false),
                  _buildCategoryChip('Audio', false),
                  _buildCategoryChip('Video', false),
                  _buildCategoryChip('Thiền', false),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Featured
            Text(
              'Nổi bật',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: BondyColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✨ Mới',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '5 bước chữa lành\nsau chia tay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '10 phút đọc • Bài viết',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Content list
            Text(
              'Dành cho bạn',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildContentItem(
              '🎧',
              'Nhạc nền thư giãn',
              '15 phút • Ambient',
              'Audio',
            ),
            _buildContentItem(
              '📝',
              'Nhật ký cảm xúc: Hướng dẫn',
              '5 phút đọc • Bài viết',
              'Bài viết',
            ),
            _buildContentItem(
              '🧘',
              'Thiền hít thở buổi sáng',
              '10 phút • Guided',
              'Audio',
            ),
            _buildContentItem(
              '🎙️',
              'Podcast: Yêu thương bản thân',
              '25 phút • Giọng đọc',
              'Audio',
            ),
            _buildContentItem(
              '📖',
              'Hiểu về attachment style',
              '8 phút đọc • Bài viết',
              'Bài viết',
            ),
            _buildContentItem(
              '🌙',
              'Thiền trước khi ngủ',
              '15 phút • Ambient',
              'Audio',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) {},
        selectedColor: BondyColors.primary,
        backgroundColor: Colors.white,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.white : BondyColors.textSecondary,
        ),
        side: BorderSide(
          color: isActive ? BondyColors.primary : BondyColors.divider,
        ),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildContentItem(
    String emoji,
    String title,
    String subtitle,
    String type,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BondyColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BondyColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: BondyColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            type == 'Audio' ? Icons.play_arrow : Icons.arrow_forward_ios,
            color: BondyColors.primary,
            size: type == 'Audio' ? 24 : 16,
          ),
        ],
      ),
    );
  }
}
