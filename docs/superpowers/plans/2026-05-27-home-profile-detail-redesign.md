# Home & Profile Detail Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Home screen and Profile Detail screen UI to match the premium Stitch designs, including a new high-compatibility suggested profiles section with full real data, updated brand logo mini on Home, and a horizontal photo gallery + relationship goals + icebreaker prompts on the Profile Detail screen.

**Architecture:** Extend data model `DiscoverProfile` to parse additional fields from the API. Implement high-compatibility sorting in Home screen, render suggested profiles, and build the redesigned layouts using custom widgets with Jakarta Sans fonts and the warm cream palette.

**Tech Stack:** Flutter, Google Fonts (Plus Jakarta Sans)

---

## Chunk 1: Model Update

### Task 1: Update DiscoverProfile Model to Parse Photos and Dating Goal

**Files:**
- Modify: `lib/models/discover/discover_profile_model.dart`

- [ ] **Step 1: Modify class fields in DiscoverProfile**
  Add `photos` and `datingGoal` to `DiscoverProfile` class definition:
  ```dart
  final List<String> photos;
  final String? datingGoal;
  ```
  And update the constructor to require/allow these fields:
  ```dart
  const DiscoverProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.distance,
    required this.bio,
    this.vibe,
    this.prompts = const [],
    required this.tags,
    required this.matchPercentage,
    required this.imageUrl,
    this.photos = const [],
    this.datingGoal,
  });
  ```

- [ ] **Step 2: Parse photos and datingGoal in fromJson**
  Update `fromJson` factory method:
  ```dart
  factory DiscoverProfile.fromJson(Map<String, dynamic> json) {
    final photosRaw = (json['photos'] as List<dynamic>?) ?? [];
    final List<String> photosList = [];
    Map<String, dynamic>? primaryPhoto;
    Map<String, dynamic>? fallbackPhoto;
    for (final photo in photosRaw) {
      if (photo is! Map<String, dynamic>) continue;
      final url = photo['url']?.toString();
      if (url != null && url.isNotEmpty) {
        final rewritten = rewriteMediaUrl(url);
        if (rewritten != null) {
          photosList.add(rewritten);
        }
      }
      fallbackPhoto ??= photo;
      if (photo['isPrimary'] == true) {
        primaryPhoto = photo;
      }
    }
    
    final promptsRaw = (json['prompts'] as List<dynamic>?) ?? [];
    
    return DiscoverProfile(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Ẩn danh',
      age: (json['age'] as num?)?.toInt() ?? 0,
      distance: json['city']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      vibe: json['vibe']?.toString(),
      prompts: promptsRaw
          .whereType<Map<String, dynamic>>()
          .map(DiscoverPrompt.fromJson)
          .toList(),
      tags: ((json['interests'] as List<dynamic>?) ??
              (json['commonInterests'] as List<dynamic>?) ??
              [])
          .map((tag) => tag.toString())
          .toList(),
      matchPercentage: (json['matchPercentage'] as num?)?.toInt() ?? 0,
      imageUrl: rewriteMediaUrl(
            primaryPhoto?['url']?.toString() ??
                fallbackPhoto?['url']?.toString(),
          ) ??
          '',
      photos: photosList,
      datingGoal: json['datingGoal']?.toString(),
    );
  }
  ```

- [ ] **Step 3: Commit model changes**
  Run: `git commit -am "feat(model): parse photos and datingGoal in DiscoverProfile"`

---

## Chunk 2: Profile Detail Redesign

### Task 2: Redesign Profile Detail Screen Layout & Header Clip

**Files:**
- Modify: `lib/screens/discover/profile_detail_screen.dart`

- [ ] **Step 1: Import bondy_logo and relevant styles**
  Ensure correct theme styles are imported, and wrap main widget content in custom styled components.

- [ ] **Step 2: Redesign header with rounded bottom corners and overlay**
  Update the FlexibleSpaceBar background in `_buildHero` or SliverAppBar to clip bottom corners:
  ```dart
  // Clip hero background
  Widget _buildHero(DiscoverProfile profile) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          profile.imageUrl.startsWith('http')
              ? Image.network(profile.imageUrl, fit: BoxFit.cover)
              : _buildHeroPlaceholder(profile),
          // Gradient Overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  ```

- [ ] **Step 3: Render Icebreaker open suggestion box**
  Add icebreaker card below bio if profile has prompts or use a placeholder based on name:
  ```dart
  Widget _buildIcebreaker(DiscoverProfile profile) {
    final icebreakerText = profile.prompts.isNotEmpty 
        ? '"${profile.prompts.first.prompt}: ${profile.prompts.first.answer}"'
        : '"Hãy thử hỏi ${profile.name} về những hoạt động cuối tuần yêu thích của cô ấy nhé."';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        border: Border.all(color: const Color(0xFFE0E7FF)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF4F46E5), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GỢI Ý MỞ LỜI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4F46E5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  icebreakerText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  ```

- [ ] **Step 4: Implement horizontal photo gallery slider**
  Add photo slider if `photos` has more than 1 image:
  ```dart
  Widget _buildPhotoGallery(DiscoverProfile profile) {
    if (profile.photos.length <= 1) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hình ảnh',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: profile.photos.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(profile.photos[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  ```

- [ ] **Step 5: Render Goal Section**
  Add dating goal display section:
  ```dart
  Widget _buildDatingGoal(DiscoverProfile profile) {
    final goalText = profile.datingGoal ?? 'Mối quan hệ lâu dài';
    final goalSubtitle = profile.datingGoal != null ? 'Mong muốn kết nối nghiêm túc' : 'Muốn tìm người bạn đời';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mục tiêu',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFFFF4B8B), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goalText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goalSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  ```

- [ ] **Step 6: Render Floating Heart button**
  Add the floating match/connect heart button in the UI overlay.

- [ ] **Step 7: Commit Profile Detail screen changes**
  Run: `git commit -am "feat(ui): redesign ProfileDetailScreen with gallery, icebreaker, and goals"`

---

## Chunk 3: Home Redesign & Suggestions

### Task 3: Redesign Home Screen Top Bar, Bento Subtitles, and Suggested Profiles List

**Files:**
- Modify: `lib/screens/home/home_dashboard_screen.dart`

- [ ] **Step 1: Update Top Bar to render BondyLogoMini**
  In `_HomeTopBar` build method, replace `Icons.bubble_chart_rounded` with `BondyLogoMini(size: 32)`:
  ```dart
  Row(
    children: [
      const BondyLogoMini(size: 32),
      const SizedBox(width: 8),
      ShaderMask(
        shaderCallback: (rect) => _Palette.gradient.createShader(rect),
        child: Text(
          'Bondy',
          style: _font(
            size: 24,
            weight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    ],
  )
  ```

- [ ] **Step 2: Change Check-in Banner text**
  In `_HealingGateBanner` update text:
  "Check-in cảm xúc hôm nay" -> "Hôm nay bạn cảm thấy như thế nào?"

- [ ] **Step 3: Update Quick Discovery Bento card titles and subtitles**
  Update `_QuickDiscoveryBento` cards subtitles:
  - "Kết đôi" -> "Tìm tri kỷ"
  - "Chữa lành" -> "Thiền & Yoga"
  - "Mối quan hệ" -> "Lời khuyên chuyên gia"

- [ ] **Step 4: Fetch Suggested Profiles with High Compatibility**
  Add `_suggestedProfiles` variable to `_HomeDashboardScreenState` and load them during `_bootstrap()`:
  ```dart
  List<DiscoverProfile> _suggestedProfiles = [];
  
  // Inside _bootstrap():
  final profiles = await _discoverService.fetchProfiles();
  profiles.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
  if (mounted) {
    setState(() {
      _suggestedProfiles = profiles.where((p) => p.matchPercentage >= 70).toList();
    });
  }
  ```

- [ ] **Step 5: Implement Suggested Profiles Horizontal List Section**
  Add `_SuggestedProfilesSection` widget:
  ```dart
  class _SuggestedProfilesSection extends StatelessWidget {
    final List<DiscoverProfile> profiles;
    
    const _SuggestedProfilesSection({required this.profiles});
    
    @override
    Widget build(BuildContext context) {
      if (profiles.isEmpty) return const SizedBox.shrink();
      
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '🔥 Gợi ý tương thích cao',
                  style: _font(size: 18, weight: FontWeight.w700, color: _Palette.onSurface),
                ),
                Text(
                  'XEM THÊM',
                  style: _font(size: 11, weight: FontWeight.w700, color: _Palette.primary, letterSpacing: 2),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/profile-detail',
                        arguments: profile,
                      );
                    },
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _Palette.outlineVariant.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              image: DecorationImage(
                                image: NetworkImage(profile.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4D6D),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${profile.matchPercentage}% Match',
                                      style: _font(size: 8, weight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${profile.name}, ${profile.age}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _font(size: 12, weight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.distance,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _font(size: 10, color: _Palette.onSurfaceMuted),
                                ),
                              ],
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
        ),
      );
    }
  }
  ```
  And render it in the home scroll view list:
  ```dart
  SliverToBoxAdapter(
    child: _SuggestedProfilesSection(profiles: _suggestedProfiles),
  ),
  ```

- [ ] **Step 6: Commit Home Screen updates**
  Run: `git commit -am "feat(ui): add brand logo, suggested profiles list, and text updates on Home Dashboard"`
