import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class DateSuggestionsWidget extends StatelessWidget {
  final List<Map<String, String>> places;
  final Function(String name)? onShare;
  final Function(String name)? onSave;
  final Function(String name)? onMap;

  const DateSuggestionsWidget({
    super.key,
    required this.places,
    this.onShare,
    this.onSave,
    this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: BondyColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Dưới đây là một vài gợi ý dành cho hai bạn:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BondyColors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 290,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: BondyColors.divider.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Place Image & Tags
                      Stack(
                        children: [
                          Image.network(
                            place['image'] ?? '',
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 140,
                              color: BondyColors.primaryLight,
                              child: const Icon(Icons.image_not_supported, color: BondyColors.primary),
                            ),
                          ),
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (place['category'] ?? '').toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: BondyColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place['name'] ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.white, size: 12),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${place['distance']} • ${place['price']} • ${place['vibe']}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Vibe Match Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: BondyColors.primaryLight.withValues(alpha: 0.35),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: BondyColors.primary, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              place['description'] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: BondyColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionButton(
                                icon: Icons.share,
                                label: 'Chia sẻ',
                                onTap: () => onShare?.call(place['name'] ?? ''),
                              ),
                              _buildActionButton(
                                icon: Icons.bookmark_border,
                                label: 'Lưu',
                                onTap: () => onSave?.call(place['name'] ?? ''),
                              ),
                              _buildActionButton(
                                icon: Icons.map_outlined,
                                label: 'Bản đồ',
                                onTap: () => onMap?.call(place['name'] ?? ''),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: BondyColors.primary, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: BondyColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
