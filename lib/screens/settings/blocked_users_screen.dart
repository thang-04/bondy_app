import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/block_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/common/bondy_widgets.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late final BlockService _blockService = BlockService(ApiClient());
  bool _loading = true;
  String? _errorMessage;
  List<BlockedUser> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await _blockService.listBlocks();
      if (!mounted) return;
      setState(() => _items = list);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Không thể tải danh sách. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmUnblock(BlockedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bỏ chặn người dùng?'),
        content: Text(
          'Sau khi bỏ chặn, ${user.name} có thể xuất hiện lại trong Discover nếu cả hai chưa swipe gần đây.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: BondyColors.primary),
            child: const Text('Bỏ chặn'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _blockService.deleteBlock(user.blockId);
      if (!mounted) return;
      setState(() => _items.removeWhere((b) => b.blockId == user.blockId));
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(title: const Text('Danh sách đã chặn')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Icon(Icons.error_outline, size: 40, color: BondyColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: bondyText(color: BondyColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(onPressed: _load, child: const Text('Thử lại')),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.block_outlined,
            size: 48,
            color: BondyColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn chưa chặn ai cả.',
            textAlign: TextAlign.center,
            style: bondyText(
              weight: FontWeight.w700,
              color: BondyColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Khi bạn chặn người dùng, họ sẽ hiển thị ở đây.',
            textAlign: TextAlign.center,
            style: bondyText(size: 13, color: BondyColors.textSecondary),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildTile(_items[index]),
    );
  }

  Widget _buildTile(BlockedUser user) {
    return Container(
      decoration: BoxDecoration(
        color: BondyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BondyColors.cardBorder),
        boxShadow: [bondySoftShadow(0.03)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildAvatar(user),
        title: Text(
          user.name,
          style: bondyText(size: 15, weight: FontWeight.w700),
        ),
        subtitle: user.blockedAt == null
            ? null
            : Text(
                'Đã chặn ${_relativeDate(user.blockedAt!)}',
                style: bondyText(size: 12, color: BondyColors.textSecondary),
              ),
        trailing: TextButton(
          onPressed: () => _confirmUnblock(user),
          child: Text(
            'Bỏ chặn',
            style: bondyText(
              weight: FontWeight.w700,
              color: BondyColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BlockedUser user) {
    final photo = user.photo;
    if (photo != null && photo.startsWith('http')) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(photo));
    }
    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: BondyColors.primaryLight,
      child: Text(
        initial,
        style: bondyText(weight: FontWeight.w800, color: BondyColors.primary),
      ),
    );
  }

  String _relativeDate(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7} tuần trước';
    if (diff.inDays >= 1) return '${diff.inDays} ngày trước';
    if (diff.inHours >= 1) return '${diff.inHours} giờ trước';
    return 'vài phút trước';
  }
}
