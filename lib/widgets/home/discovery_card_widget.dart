// lib/widgets/home/discovery_card_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscoveryCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const DiscoveryCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final profiles = (data['profiles'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Gợi ý kết nối cho bạn ✨',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ),
          if (profiles.isEmpty)
            _EmptyDiscovery()
          else
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: profiles.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final profile = profiles[index] as Map<String, dynamic>;
                  return _ProfileChip(profile: profile);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _ProfileChip({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile['name'] as String? ?? 'Ẩn danh';
    final city = profile['city'] as String? ?? '';
    final interests = (profile['common_interests'] as List<dynamic>?) ?? [];

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/discover'),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffffffff),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFb70047).withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFFFE0E6),
                  child: Icon(Icons.person, color: Color(0xFFb70047)),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF660066),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (city.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                city,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (interests.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                interests.take(2).join(', '),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: const Color(0xFF92348e),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFb70047).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        'Thêm sở thích vào profile để Bondy gợi ý tốt hơn 🎯',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: const Color(0xFF6B7280),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
