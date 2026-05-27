import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/discover/discover_profile_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/discover/prompt_chip.dart';
import 'report_bottom_sheet.dart';

class DiscoverMatchingCard extends StatelessWidget {
  final DiscoverProfile profile;

  const DiscoverMatchingCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/profile-detail', arguments: profile);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark background for the card inside
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(child: _buildImageOrPlaceholder()),

            // Gradient Overlay to make text readable
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Content overlay
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name and Age
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${profile.name}, ${profile.age}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                ReportBottomSheet(targetUserId: profile.id),
                          );
                        },
                        icon: const Icon(
                          Icons.flag_outlined,
                          color: Colors.white70,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        profile.distance,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.tags
                        .map((tag) => _buildTag(tag))
                        .toList(),
                  ),

                  const SizedBox(height: 16),

                  // Bio
                  if (profile.bio.isNotEmpty)
                    Text(
                      profile.bio,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Prompts
                  if (profile.prompts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    PromptChip(prompt: profile.prompts.first),
                  ],

                  const SizedBox(height: 8),

                  // Match percentage indicator
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: BondyColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${profile.matchPercentage}% match',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BondyColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOrPlaceholder() {
    if (profile.imageUrl.startsWith('http')) {
      return Image.network(
        profile.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    final initial = profile.name.trim().isEmpty
        ? 'B'
        : profile.name.trim()[0].toUpperCase();
    return Container(
      color: BondyColors.primaryLight,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 88,
            fontWeight: FontWeight.w800,
            color: BondyColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
