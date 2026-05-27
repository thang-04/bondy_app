import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class SoftenedDiscoverScreen extends StatelessWidget {
  const SoftenedDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Khám phá nhẹ nhàng'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BondyColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      'Không vội vàng',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: BondyColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bondy sẽ gợi ý những người có cùng\nhành trình chữa lành với bạn.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: BondyColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Gợi ý hôm nay',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(3, (index) {
                final profiles = [
                  {'name': 'Hương Ly', 'emoji': '🌻', 'status': 'Cùng hành trình chữa lành'},
                  {'name': 'Đức Minh', 'emoji': '🌿', 'status': 'Thích thiền định & yoga'},
                  {'name': 'Ngọc Trâm', 'emoji': '🌸', 'status': 'Yêu thích đọc sách'},
                ];
                final p = profiles[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BondyColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: BondyColors.primaryLight,
                        child: Text(p['emoji']!,
                            style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p['status']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: BondyColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Xem'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
