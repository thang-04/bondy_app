import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_client.dart';
import '../../services/chat_service.dart';
import '../../services/match_service.dart';
import '../../theme/app_theme.dart';

class MatchesListScreen extends StatefulWidget {
  final bool embedded;

  const MatchesListScreen({super.key, this.embedded = false});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen> {
  late final ApiClient _apiClient = ApiClient();
  late final ChatService _chatService = ChatService(_apiClient);
  late final MatchService _matchService = MatchService(_apiClient);
  List<ChatMatch> _chats = [];
  List<PendingMatch> _pendingMatches = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadAll(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _chatService.listChats(),
        _matchService.listMatches(),
      ]);
      if (!mounted) return;
      final allMatches = results[1] as List<PendingMatch>;
      setState(() {
        _chats = results[0] as List<ChatMatch>;
        _pendingMatches = allMatches.where((m) => m.needsConfirmation).toList();
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _errorMessage = 'Không thể tải danh sách tin nhắn.');
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, widget.embedded ? 16 : 8, 16, 24),
        children: [
          _buildBondyEntry(context),
          if (_pendingMatches.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Chờ xác nhận',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BondyColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ..._pendingMatches.map(_buildPendingTile),
          ],
          const SizedBox(height: 16),
          Text(
            'Cuộc trò chuyện',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BondyColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            _buildMessageState(
              icon: Icons.error_outline,
              title: _errorMessage!,
              actionLabel: 'Thử lại',
              onAction: _loadAll,
            )
          else if (_chats.isEmpty && _pendingMatches.isEmpty)
            _buildMessageState(
              icon: Icons.forum_outlined,
              title: 'Chưa có cuộc trò chuyện nào',
              actionLabel: 'Khám phá',
              onAction: () => Navigator.of(context).pushNamed('/discover'),
            )
          else if (_chats.isEmpty)
            const SizedBox.shrink()
          else
            ..._chats.map((chat) => _buildChatTile(context, chat)),
        ],
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: BondyColors.background,
        body: SafeArea(child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tin nhắn'),
      ),
      body: body,
    );
  }

  Widget _buildPendingTile(PendingMatch match) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: BondyColors.primaryLight.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: _buildAvatar(match.otherUserPhoto, match.otherUserName),
        title: Text(
          match.otherUserName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Cần xác nhận để mở chat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: BondyColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: BondyColors.primary),
        onTap: () => Navigator.of(context).pushNamed(
          '/match-confirm',
          arguments: {'matchId': match.id},
        ),
      ),
    );
  }

  Widget _buildBondyEntry(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: BondyColors.primaryGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'B',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Text(
          'Hỏi Bondy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          'Trò chuyện với AI chữa lành',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 16,
        ),
        onTap: () => Navigator.of(context).pushNamed('/chatbot'),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatMatch chat) {
    final displayName = chat.otherUser.displayName.isEmpty
        ? 'Bondy user'
        : chat.otherUser.displayName;
    final lastMessage = chat.lastMessage?.content ?? 'Bắt đầu cuộc trò chuyện';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: _buildAvatar(chat.otherUser.photo, displayName),
        title: Text(
          displayName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          lastMessage,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: BondyColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTime(chat.lastMessage?.createdAt ?? chat.updatedAt),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: BondyColors.textHint,
          ),
        ),
        onTap: () => Navigator.of(context).pushNamed(
          '/chat',
          arguments: {
            'chatId': chat.id,
            'matchId': chat.matchId,
            'otherUserId': chat.otherUser.id,
            'name': displayName,
            'photo': chat.otherUser.photo,
          },
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 40, color: BondyColors.textHint),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: BondyColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photo, String displayName) {
    if (photo != null && photo.startsWith('http')) {
      return CircleAvatar(radius: 24, backgroundImage: NetworkImage(photo));
    }

    final initial = displayName.trim().isEmpty
        ? 'B'
        : displayName.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 24,
      backgroundColor: BondyColors.primaryLight,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
