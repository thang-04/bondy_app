import 'package:flutter/material.dart';
import '../../services/relationship_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/relationship/mood_distribution_chart.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final _service = RelationshipService();
  Map<String, dynamic>? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.fetchWeeklyReport();
      setState(() => _report = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(
        backgroundColor: BondyColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: BondyColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Báo cáo tuần',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: BondyColors.primary),
              )
            : _error != null
            ? _buildError()
            : _report == null
            ? _buildNoRelationship()
            : _buildReport(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: BondyColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRelationship() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Bạn chưa có mối quan hệ đang hoạt động.',
          textAlign: TextAlign.center,
          style: TextStyle(color: BondyColors.textSecondary, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildReport() {
    final summary = _report!['weekSummary'] as Map<String, dynamic>? ?? {};
    final milestones = (_report!['upcomingMilestones'] as List<dynamic>?) ?? [];
    final moods = (summary['moodDistribution'] as List<dynamic>?) ?? [];
    final streak = (_report!['streakDays'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStreakCard(streak),
          const SizedBox(height: 16),
          _buildStatGrid(summary),
          const SizedBox(height: 16),
          if (moods.isNotEmpty) ...[
            _sectionTitle('Tâm trạng trong tuần'),
            const SizedBox(height: 10),
            MoodDistributionChart(
              entries: moods
                  .whereType<Map<String, dynamic>>()
                  .map(
                    (m) => MoodEntry(
                      mood: m['mood']?.toString() ?? '',
                      percentage: (m['percentage'] as num?)?.toInt() ?? 0,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (milestones.isNotEmpty) ...[
            _sectionTitle('Cột mốc sắp tới'),
            const SizedBox(height: 10),
            ...milestones.whereType<Map<String, dynamic>>().map(
              (m) => _buildMilestoneRow(m),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BondyColors.primary, BondyColors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak ngày streak',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Tiếp tục duy trì nhé!',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(Map<String, dynamic> summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard(
          'Check-in cá nhân',
          '${(summary['personalCheckins'] as num?)?.toInt() ?? 0}',
          Icons.person_outline,
        ),
        _statCard(
          'Check-in cặp đôi',
          '${(summary['coupleCheckins'] as num?)?.toInt() ?? 0}',
          Icons.favorite_outline,
        ),
        _statCard(
          'Tin nhắn',
          '${(summary['messagesExchanged'] as num?)?.toInt() ?? 0}',
          Icons.chat_bubble_outline,
        ),
        _statCard(
          'Nội dung healing',
          '${(summary['healingCompletions'] as num?)?.toInt() ?? 0}',
          Icons.auto_awesome_outlined,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BondyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BondyColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: BondyColors.primary, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: BondyColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: BondyColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(Map<String, dynamic> m) {
    final date = DateTime.tryParse(m['date']?.toString() ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BondyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BondyColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_outline, color: BondyColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              m['title']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: BondyColors.textPrimary,
              ),
            ),
          ),
          if (date != null)
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(
                fontSize: 12,
                color: BondyColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: BondyColors.textPrimary,
      ),
    );
  }
}
