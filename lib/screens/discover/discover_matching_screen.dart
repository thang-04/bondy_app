import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/discover/discover_viewmodel.dart';
import 'widgets/discover_matching_card.dart';

class DiscoverMatchingScreen extends StatefulWidget {
  const DiscoverMatchingScreen({super.key});

  @override
  State<DiscoverMatchingScreen> createState() => _DiscoverMatchingScreenState();
}

class _DiscoverMatchingScreenState extends State<DiscoverMatchingScreen> {
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  late final DiscoverViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DiscoverViewModel();
    _viewModel.loadProfiles();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onSwipeEnd(int previousIndex, int targetIndex, SwiperActivity activity) {
    if (activity is Swipe) {
      final profiles = _viewModel.profiles;
      if (previousIndex >= profiles.length) return;
      final direction = activity.direction.toString().toLowerCase();
      final action = direction.contains('right') || direction.contains('up') ? 'LIKE' : 'PASS';
      _viewModel.swipe(profiles[previousIndex].id, action);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Khám phá'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/discover/softened'),
            icon: const Icon(Icons.spa_outlined),
            tooltip: 'Chế độ nhẹ nhàng',
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            if (_viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator(color: BondyColors.primary));
            }

            if (_viewModel.errorMessage != null && _viewModel.profiles.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_viewModel.errorMessage!, textAlign: TextAlign.center),
                ),
              );
            }

            if (_viewModel.isEmpty) {
              return const Center(child: Text('Chưa có gợi ý phù hợp. Hãy quay lại sau nhé.'));
            }

            final profiles = _viewModel.profiles;
            return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Người phù hợp với bạn',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dựa trên sự đồng điệu cảm xúc',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: BondyColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Expanded area for the Swiper
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AppinioSwiper(
                  controller: _swiperController,
                  onSwipeEnd: _onSwipeEnd,
                  cardCount: profiles.length,
                  cardBuilder: (BuildContext context, int index) {
                    return DiscoverMatchingCard(profile: profiles[index]);
                  },
                ),
              ),
            ),
            
            // Bottom Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dislike / Swipe Left
                  _buildActionButton(
                    icon: Icons.close,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      _swiperController.swipeLeft();
                    },
                  ),
                  const SizedBox(width: 24),
                  
                  // Super Like
                  _buildActionButton(
                    icon: Icons.star_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      _swiperController.swipeUp();
                    },
                    size: 64, // Larger central button
                    iconSize: 32,
                  ),
                  const SizedBox(width: 24),
                  
                  // Like / Swipe Right
                  _buildActionButton(
                    icon: Icons.favorite,
                    color: BondyColors.primary,
                    onTap: () {
                      _swiperController.swipeRight();
                    },
                  ),
                ],
              ),
            ),
          ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
    double iconSize = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}

