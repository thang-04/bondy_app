import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class RelationshipHomeDashboard extends StatelessWidget {
  const RelationshipHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Của chúng mình',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: BondyColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Hoan & Linh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: BondyColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=hoan_linh'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Relationship Streak Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: BondyColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: BondyColors.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '365 ngày bên nhau',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kỷ niệm 1 năm sắp tới rồi! ❤️',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Grid
              Text(
                'Hoạt động cặp đôi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildActionCard(
                    context,
                    'Emotional\nCheck-in',
                    Icons.favorite_outline,
                    const Color(0xFFFFE5E5),
                    const Color(0xFFFF5252),
                    '/relationship/checkin',
                  ),
                  _buildActionCard(
                    context,
                    'Conflict\nResolver',
                    Icons.handshake_outlined,
                    const Color(0xFFE5F6FF),
                    const Color(0xFF2196F3),
                    '/relationship/conflict-tool',
                  ),
                  _buildActionCard(
                    context,
                    'Relationship\nMilestones',
                    Icons.emoji_events_outlined,
                    const Color(0xFFFFF7E5),
                    const Color(0xFFFFB300),
                    '/relationship/milestones',
                  ),
                  _buildActionCard(
                    context,
                    'Partner\nInvite',
                    Icons.person_add_outlined,
                    const Color(0xFFF3E5FF),
                    const Color(0xFF9C27B0),
                    '/relationship/invite',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Shared Memories / Upcoming
              Text(
                'Kỷ niệm sắp tới',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildMemoryItem('Kỷ niệm 1 năm', 'Còn 14 ngày', '🎂'),
              _buildMemoryItem('Chuyến du lịch tiếp theo', 'Tháng sau', '✈️'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor,
    String route,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 28),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: BondyColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryItem(String title, String subtitle, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BondyColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: BondyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}
