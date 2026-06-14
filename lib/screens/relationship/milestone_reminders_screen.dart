import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../healing/healing_stitch_style.dart';
import '../../core/bondy_error_mapper.dart';
import '../../services/relationship_service.dart';
import '../../widgets/common/bondy_feedback.dart';

class MilestoneRemindersScreen extends StatefulWidget {
  const MilestoneRemindersScreen({super.key});

  @override
  State<MilestoneRemindersScreen> createState() =>
      _MilestoneRemindersScreenState();
}

class _MilestoneRemindersScreenState extends State<MilestoneRemindersScreen> {
  final RelationshipService _service = RelationshipService();
  List<Map<String, dynamic>> _milestones = [];
  bool _loading = true;
  String? _error;

  String _selectedTab = 'Tin nhắn';

  final Map<String, List<Map<String, String>>> _suggestions = {
    'Tin nhắn': [
      {
        'title': 'Thinking of you',
        'category': 'Short & Sweet',
        'content':
            'Happy anniversary to my better half. Every moment with you is a treasure.',
        'image':
            'https://images.unsplash.com/photo-1518199266791-5375a83190b7?q=80&w=300&auto=format&fit=crop',
      },
      {
        'title': 'Happy Anniversary',
        'category': 'Classic',
        'content':
            'Cheers to another year of love, laughter, and happiness. I love you!',
        'image':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=300&auto=format&fit=crop',
      },
      {
        'title': 'My Love',
        'category': 'Emotional',
        'content':
            'You are my rock, my love, and my best friend. Here\'s to us forever.',
        'image':
            'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?q=80&w=300&auto=format&fit=crop',
      },
    ],
    'Hẹn hò': [
      {
        'title': 'Bữa tối lãng mạn',
        'category': 'Cozy & Sweet',
        'content':
            'Cùng nấu một bữa tối ấm cúng tại nhà dưới ánh nến lung linh và nhạc nhẹ.',
        'image':
            'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=300&auto=format&fit=crop',
      },
      {
        'title': 'Đêm nhạc acoustic',
        'category': 'Chill Vibe',
        'content':
            'Dành buổi tối tại một quán cà phê acoustic và lắng nghe những bản tình ca.',
        'image':
            'https://images.unsplash.com/photo-1511192336575-5a79af67a629?q=80&w=300&auto=format&fit=crop',
      },
    ],
    'Quà tặng': [
      {
        'title': 'Hoa dại rực rỡ',
        'category': 'Surprise',
        'content':
            'Một bó hoa dại nhỏ đặt trên bàn làm việc của người ấy vào sáng sớm.',
        'image':
            'https://images.unsplash.com/photo-1490750967868-88aa4486c946?q=80&w=300&auto=format&fit=crop',
      },
      {
        'title': 'Bức thư viết tay',
        'category': 'Meaningful',
        'content':
            'Viết một bức thư tay kể lại những khoảnh khắc đáng nhớ nhất của hai bạn trong năm qua.',
        'image':
            'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=300&auto=format&fit=crop',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _milestones = await _service.listMilestones();
    } catch (e) {
      _error = BondyErrorMapper.message(e);
      _milestones = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddDialog() async {
    final titleController = TextEditingController();
    DateTime selected = DateTime.now().add(const Duration(days: 30));

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFFDFB),
        title: Text(
          'Thêm cột mốc mới 📅',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Nhập tiêu đề (vd: Kỷ niệm 1 năm...)',
                hintStyle: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selected,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) selected = picked;
              },
              child: Text(
                'Chọn ngày kỷ niệm',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Lưu lại',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFFF6B6B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (saved != true || titleController.text.trim().isEmpty) return;

    try {
      await _service.addMilestone(
        title: titleController.text.trim(),
        milestoneDate: selected,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    }
  }

  int _calculateDaysLeft(Map<String, dynamic>? milestone) {
    if (milestone == null) return 5; // Fallback default
    final dateStr = milestone['milestoneDate']?.toString();
    if (dateStr == null) return 5;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 5;
    final diff = date.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Tìm cột mốc sắp tới gần nhất
    Map<String, dynamic>? nextMilestone;
    for (final m in _milestones) {
      final d = DateTime.tryParse(m['milestoneDate']?.toString() ?? '');
      if (d != null && !d.isBefore(now)) {
        if (nextMilestone == null) {
          nextMilestone = m;
        } else {
          final nextD = DateTime.tryParse(
            nextMilestone['milestoneDate']?.toString() ?? '',
          );
          if (nextD != null && d.isBefore(nextD)) {
            nextMilestone = m;
          }
        }
      }
    }

    final daysLeft = _calculateDaysLeft(nextMilestone);

    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      appBar: AppBar(
        backgroundColor: HealingStitchColors.creamBackground,
        elevation: 0,
        leading: HealingIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.pop(context),
        ),
        title: Text(
          'Upcoming Milestone',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: HealingStitchColors.textMain,
          ),
        ),
        centerTitle: true,
        actions: [
          HealingIconButton(icon: Icons.calendar_month, onTap: _showAddDialog),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: HealingStitchColors.coral,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: HealingStitchColors.coral,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: healingText(
                                color: HealingStitchColors.textSoft,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Banner Countdown lớn
                          _buildCountdownBanner(nextMilestone, daysLeft),
                          const SizedBox(height: 28),

                          // Gợi ý cho bạn
                          Text(
                            'Gợi ý cho bạn',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: HealingStitchColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bộ lọc Tab ngang
                          _buildTabFilter(),
                          const SizedBox(height: 16),

                          // List ngang suggestions
                          _buildSuggestionsList(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sticky Bottom Plan button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8C61), Color(0xFFFFB74D)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFFB74D,
                          ).withValues(alpha: 0.35),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _showAddDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.edit_calendar,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Plan This Event',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCountdownBanner(
    Map<String, dynamic>? nextMilestone,
    int daysLeft,
  ) {
    if (nextMilestone == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: HealingStitchColors.border),
          boxShadow: [healingSoftShadow(0.04)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Chưa có cột mốc nào sắp tới',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: HealingStitchColors.textMain,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy cùng nhau tạo những cột mốc kỷ niệm ý nghĩa như ngày yêu nhau, ngày gặp đầu tiên...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: HealingStitchColors.textSoft,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Thêm cột mốc đầu tiên',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: HealingStitchColors.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final title = nextMilestone['title']?.toString() ?? '';
    final dateStr = nextMilestone['milestoneDate']?.toString();
    String dateLabel = 'Chưa thiết lập';
    if (dateStr != null) {
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        dateLabel = '${date.day} Thg ${date.month}, ${date.year}';
      }
    }

    return Container(
      width: double.infinity,
      height: 360,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Image
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCUj7G5ofM-bxrbtBl061wYGbExbsLjexEkxeFC0V2XuhekUIb-54LC8QMoj0KzbA2rTOM-bKD0-h1szZawjaqwNoQhmTJpSf7m7eFUDyi8X3inu06rGkSPrwVxKwzUvYz7LKbYytk_d9lUDI3seFD98ZOQyis9UWpVkvGI4dwjDptAOyUxVguVDsLil5rnJXz0fLr_gChNbqBpBwplk4I5uQFUohw3s0uK-Qrb4JwxqnHOd3vdQvNJWThBq88vU8pUkgZdUybazSh3',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          // Gradient Overlay mờ
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEDE2B),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Sắp diễn ra',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kỷ niệm của hai bạn sắp đến',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event, color: Color(0xFFEEDE2B), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Countdown Box
                Row(
                  children: [
                    _buildCountdownUnit(
                      daysLeft.toString().padLeft(2, '0'),
                      'Days',
                    ),
                    const SizedBox(width: 8),
                    _buildCountdownUnit('12', 'Hours'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownUnit(String num, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            num,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: HealingStitchColors.textMain,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: HealingStitchColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabFilter() {
    final tabs = ['Tin nhắn', 'Hẹn hò', 'Quà tặng'];
    final icons = [
      Icons.chat_bubble_outline,
      Icons.favorite_border,
      Icons.card_giftcard,
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final icon = icons[index];
          final isSelected = _selectedTab == tab;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFB74D)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFFFFB74D)
                          : HealingStitchColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? const Color(0xFFFFB74D)
                            : HealingStitchColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final list = _suggestions[_selectedTab] ?? [];

    return SizedBox(
      height: 290,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];

          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: HealingStitchColors.border),
              boxShadow: [healingSoftShadow(0.03)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(item['image']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['category']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: HealingStitchColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    item['content']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: HealingStitchColors.textSoft,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item['content']!));
                      BondyFeedback.showSuccess(
                        context,
                        'Đã sao chép nội dung gợi ý!',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.content_copy,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Copy Text',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: HealingStitchColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
