// lib/widgets/home/suggestion_card_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const SuggestionCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Dành riêng cho bạn hôm nay';
    final content = data['content'] as String? ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB3A7), Color(0xFFE8A0BF), Color(0xFFAE8FDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8A0BF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFffbdf4),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              'DAILY INSPIRATION',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7a1c78),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Center(child: Text('🧘‍♀️', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/content'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF0066), Color(0xFFFF007F)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bắt đầu hành trình',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
