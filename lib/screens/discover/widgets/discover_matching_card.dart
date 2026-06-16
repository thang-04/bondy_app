import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/discover/discover_profile_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/discover/prompt_chip.dart';
import 'report_bottom_sheet.dart';

class DiscoverMatchingCard extends StatefulWidget {
  final DiscoverProfile profile;
  final Future<void> Function(DiscoverProfile profile)? onOpenDetail;

  const DiscoverMatchingCard({
    super.key,
    required this.profile,
    this.onOpenDetail,
  });

  @override
  State<DiscoverMatchingCard> createState() => _DiscoverMatchingCardState();
}

class _DiscoverMatchingCardState extends State<DiscoverMatchingCard> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.profile.photos.isNotEmpty
        ? widget.profile.photos
        : (widget.profile.imageUrl.isNotEmpty
              ? [widget.profile.imageUrl]
              : <String>[]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;

        return GestureDetector(
          onTapUp: (details) async {
            final x = details.localPosition.dx;
            final y = details.localPosition.dy;

            // If tapped in the bottom info section, open detail
            if (y > cardHeight * 0.6) {
              await _openDetail();
              return;
            }

            if (x < cardWidth * 0.35) {
              // Tap left side: Previous photo
              if (_currentPhotoIndex > 0) {
                setState(() {
                  _currentPhotoIndex--;
                });
              }
            } else if (x > cardWidth * 0.65) {
              // Tap right side: Next photo
              if (_currentPhotoIndex < photos.length - 1) {
                setState(() {
                  _currentPhotoIndex++;
                });
              }
            } else {
              // Middle tap opens detail
              await _openDetail();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(
                0xFF1E1E1E,
              ), // Dark background for the card inside
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
                Positioned.fill(child: _buildImageOrPlaceholder(photos)),

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

                // Tinder-style progress indicators
                if (photos.length > 1)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: List.generate(
                        photos.length,
                        (idx) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            decoration: BoxDecoration(
                              color: idx == _currentPhotoIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
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
                              '${widget.profile.name}, ${widget.profile.age}',
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
                                builder: (_) => ReportBottomSheet(
                                  targetUserId: widget.profile.id,
                                ),
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

                      if (widget.profile.distance.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.profile.distance,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (widget.profile.datingGoal != null &&
                          widget.profile.datingGoal!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFFF4B8B),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getDatingGoalText(widget.profile.datingGoal),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...widget.profile.tags
                              .take(3)
                              .map((tag) => _buildTag(tag)),
                          if (widget.profile.tags.length > 3) _buildTag('...'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Bio
                      if (widget.profile.bio.isNotEmpty)
                        Text(
                          widget.profile.bio,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      // Prompts
                      if (widget.profile.prompts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        PromptChip(prompt: widget.profile.prompts.first),
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
                            '${widget.profile.matchPercentage}% match',
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
      },
    );
  }

  Future<void> _openDetail() async {
    final callback = widget.onOpenDetail;
    if (callback != null) {
      await callback(widget.profile);
      return;
    }
    await Navigator.of(
      context,
    ).pushNamed('/profile-detail', arguments: widget.profile);
  }

  Widget _buildImageOrPlaceholder(List<String> photos) {
    if (photos.isNotEmpty && _currentPhotoIndex < photos.length) {
      final url = photos[_currentPhotoIndex];
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          // Giới hạn decode size để giảm bộ nhớ → giảm lag.
          cacheWidth: 720,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingPlaceholder(loadingProgress);
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildLoadingPlaceholder(ImageChunkEvent progress) {
    final total = progress.expectedTotalBytes;
    final fraction = total != null && total > 0
        ? progress.cumulativeBytesLoaded / total
        : null;
    return Container(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: fraction,
            strokeWidth: 3,
            color: BondyColors.primary.withValues(alpha: 0.7),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final initial = widget.profile.name.trim().isEmpty
        ? 'B'
        : widget.profile.name.trim()[0].toUpperCase();
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

  String _getDatingGoalText(String? goal) {
    switch (goal) {
      case 'LONG_TERM':
        return 'Yêu lâu dài';
      case 'MARRIAGE':
        return 'Tìm bạn đời';
      case 'DATING':
        return 'Hẹn hò';
      case 'FRIENDSHIP':
        return 'Kết bạn';
      case 'NOT_SURE':
        return 'Chưa rõ';
      default:
        return goal ?? '';
    }
  }
}
