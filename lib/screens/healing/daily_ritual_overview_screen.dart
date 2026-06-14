import 'package:flutter/material.dart';

import '../../core/bondy_error_mapper.dart';
import '../../models/healing/healing_models.dart';
import '../../services/healing/healing_service.dart';
import 'healing_stitch_style.dart';

class DailyRitualOverviewScreen extends StatefulWidget {
  final HealingDataSource? service;

  const DailyRitualOverviewScreen({super.key, this.service});

  @override
  State<DailyRitualOverviewScreen> createState() =>
      _DailyRitualOverviewScreenState();
}

class _DailyRitualOverviewScreenState extends State<DailyRitualOverviewScreen> {
  late final HealingDataSource _service;
  bool _isLoading = true;
  String? _errorMessage;
  List<HealingContentPreview> _items = const [];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? HealingService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final home = await _service.fetchHome();
      final combined = <HealingContentPreview>[
        ...home.sections.rituals,
        ...home.sections.exercises,
      ];
      if (!mounted) return;
      setState(() => _items = combined);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = BondyErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<HealingContentPreview> _filterByDuration(int min, int max) {
    return _items.where((item) {
      final minutes = item.estimatedMinutes ?? 5;
      return minutes >= min && minutes <= max;
    }).toList();
  }

  String _routeFor(HealingContentPreview item) {
    final type = item.type.toUpperCase();
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    return switch (type) {
      'AUDIO' => '/healing/ritual-audio-detail',
      'EXERCISE' => '/healing/exercise-detail',
      'ARTICLE' => '/healing/article-detail',
      'RITUAL' =>
        tags.contains('audio') || tags.contains('breathing')
            ? '/healing/ritual-audio-detail'
            : '/healing/ritual-reading-detail',
      _ => '/healing/ritual-reading-detail',
    };
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: HealingStitchColors.creamBackground,
        appBar: AppBar(
          title: const Text('Nghi thức dành cho trạng thái hiện tại'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '3 phút'),
              Tab(text: '5-10 phút'),
              Tab(text: '15+ phút'),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: HealingStitchColors.pink),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Chưa có nghi thức nào khả dụng.'));
    }
    return TabBarView(
      children: [
        _RitualList(items: _filterByDuration(0, 4), routeBuilder: _routeFor),
        _RitualList(items: _filterByDuration(5, 14), routeBuilder: _routeFor),
        _RitualList(items: _filterByDuration(15, 240), routeBuilder: _routeFor),
      ],
    );
  }
}

class _RitualList extends StatelessWidget {
  final List<HealingContentPreview> items;
  final String Function(HealingContentPreview item) routeBuilder;

  const _RitualList({required this.items, required this.routeBuilder});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Chưa có nội dung phù hợp.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) {
        final item = items[i];
        return Card(
          child: ListTile(
            title: Text(
              item.title,
              style: healingText(weight: FontWeight.w800),
            ),
            subtitle: Text(
              item.summary.isNotEmpty
                  ? item.summary
                  : '${item.estimatedMinutes ?? 5} phút',
              style: healingText(size: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.of(
              context,
            ).pushNamed(routeBuilder(item), arguments: item.id),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemCount: items.length,
    );
  }
}
