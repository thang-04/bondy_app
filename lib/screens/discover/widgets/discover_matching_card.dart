import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/discover/discover_profile_model.dart';
import '../../../theme/app_theme.dart';

class DiscoverMatchingCard extends StatelessWidget {
  final DiscoverProfile profile;

  const DiscoverMatchingCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // You can also pass `profile` arguments here if the profile-detail screen expects them
        Navigator.of(context).pushNamed('/profile-detail');
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
          Positioned.fill(
            child: _buildImageOrPlaceholder(),
          ),
          
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
                Text(
                  '${profile.name}, ${profile.age}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
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
                  children: profile.tags.map((tag) => _buildTag(tag)).toList(),
                ),

                const SizedBox(height: 16),

                // Bio
                Text(
                  profile.bio,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                
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
    return Container(
      color: BondyColors.primaryLight,
      child: Center(
        child: Text(
          profile.imageUrl, // Treated as emoji if not URL
          style: const TextStyle(fontSize: 100),
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
