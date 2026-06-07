import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/relationship_service.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../healing/healing_stitch_style.dart';

class RelationshipTimelineScreen extends StatefulWidget {
  final RelationshipService? service;

  const RelationshipTimelineScreen({super.key, this.service});

  @override
  State<RelationshipTimelineScreen> createState() =>
      _RelationshipTimelineScreenState();
}

class _RelationshipTimelineScreenState
    extends State<RelationshipTimelineScreen> {
  late final RelationshipService _service;
  late Future<List<RelationshipTimelineItem>> _future;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? RelationshipService();
    _future = _service.fetchTimeline();
  }

  void _reload() {
    setState(() {
      _future = _service.fetchTimeline();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = _routeFilter(context);

    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      appBar: AppBar(
        backgroundColor: HealingStitchColors.warmBackground,
        elevation: 0,
        foregroundColor: HealingStitchColors.textMain,
        title: Text(
          filter == 'CHECKIN' ? 'Lịch sử cảm xúc' : 'Dòng thời gian',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<RelationshipTimelineItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const BondyLoadingState(label: 'Đang tải dòng thời gian...');
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: BondyErrorBanner.fromError(
                snapshot.error,
                onRetry: _reload,
              ),
            );
          }

          final items = _filteredItems(snapshot.data ?? const [], filter);
          if (items.isEmpty) {
            return BondyEmptyState(
              title: filter == 'CHECKIN'
                  ? 'Chưa có check-in cảm xúc'
                  : 'Chưa có kỷ niệm nào',
              subtitle: filter == 'CHECKIN'
                  ? 'Khi hai bạn check-in, lịch sử sẽ xuất hiện ở đây.'
                  : 'Các cột mốc và check-in của hai bạn sẽ được lưu tại đây.',
              actionLabel: filter == 'CHECKIN' ? 'Check-in ngay' : null,
              onAction: filter == 'CHECKIN'
                  ? () =>
                        Navigator.of(context).pushNamed('/relationship/checkin')
                  : null,
            );
          }

          return RefreshIndicator(
            color: HealingStitchColors.coral,
            onRefresh: () async => _reload(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) =>
                  _TimelineCard(item: items[index]),
            ),
          );
        },
      ),
    );
  }

  String? _routeFilter(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) return args['filter']?.toString();
    return null;
  }

  List<RelationshipTimelineItem> _filteredItems(
    List<RelationshipTimelineItem> items,
    String? filter,
  ) {
    if (filter == null || filter.isEmpty) return items;
    return items.where((item) {
      switch (filter) {
        case 'CHECKIN':
          return item.type == RelationshipTimelineItemType.checkin;
        case 'MILESTONE':
          return item.type == RelationshipTimelineItemType.milestone;
        case 'STARTED':
          return item.type == RelationshipTimelineItemType.started;
        default:
          return true;
      }
    }).toList();
  }
}

class _TimelineCard extends StatelessWidget {
  final RelationshipTimelineItem item;

  const _TimelineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HealingStitchColors.border),
        boxShadow: [healingSoftShadow(0.04)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(_icon, color: _accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HealingStitchColors.textMain,
                  ),
                ),
                if ((item.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.45,
                      color: HealingStitchColors.textSoft,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  _formatDate(item.occurredAt),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: HealingStitchColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _accentColor {
    switch (item.type) {
      case RelationshipTimelineItemType.started:
        return Colors.pink.shade400;
      case RelationshipTimelineItemType.checkin:
        return Colors.teal.shade600;
      case RelationshipTimelineItemType.milestone:
        return Colors.orange.shade700;
    }
  }

  IconData get _icon {
    switch (item.type) {
      case RelationshipTimelineItemType.started:
        return Icons.favorite;
      case RelationshipTimelineItemType.checkin:
        return Icons.mood;
      case RelationshipTimelineItemType.milestone:
        return Icons.celebration_outlined;
    }
  }

  String get _label {
    switch (item.type) {
      case RelationshipTimelineItemType.started:
        return 'Bắt đầu';
      case RelationshipTimelineItemType.checkin:
        return 'Check-in';
      case RelationshipTimelineItemType.milestone:
        return 'Cột mốc';
    }
  }

  String _formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$hour:$minute • $day/$month/${date.year}';
  }
}
