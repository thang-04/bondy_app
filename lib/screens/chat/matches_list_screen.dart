import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/chat_service.dart';
import '../../services/match_service.dart';
import '../../theme/app_theme.dart';
import '../../core/ai_prompts_config.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../widgets/chat/ask_bondy_bottom_sheet.dart';

class MatchesListScreen extends StatefulWidget {
  final bool embedded;

  const MatchesListScreen({super.key, this.embedded = false});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen> {
  late final ApiClient _apiClient = ApiClient();
  late final MatchService _matchService = MatchService(_apiClient);
  List<PendingMatch> _pendingMatches = [];
  String? _errorMessage;
  Timer? _refreshTimer;
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll({bool silent = false}) async {
    final chatVM = context.read<ChatViewModel>();
    if (!silent) {
      setState(() => _errorMessage = null);
    }
    try {
      await Future.wait([
        chatVM.fetchChats(),
        _matchService.listMatches().then((matches) {
          if (!mounted) return;
          setState(() {
            _pendingMatches =
                matches.where((m) => m.needsConfirmation).toList();
          });
        }),
      ]);
      if (!mounted) return;
      setState(() => _errorMessage = null);
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _errorMessage = 'Không thể tải danh sách tin nhắn.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();
    final isLoading = chatVM.isLoading;
    final filteredChats = chatVM.chats.where((chat) {
      final name = chat.otherUser.displayName.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    final body = RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, widget.embedded ? 16 : 8, 16, widget.embedded ? 165 : 24),
        children: [
          _buildHeaderTitle(context),
          const SizedBox(height: 12),
          _buildSearchField(),
          const SizedBox(height: 16),
          if (_pendingMatches.isNotEmpty) ...[
            Text(
              'Mới tương hợp',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: BondyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildHorizontalPendingList(),
            const SizedBox(height: 16),
          ],
          Text(
            'Tin nhắn',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: BondyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (isLoading && filteredChats.isEmpty)
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
          else if (filteredChats.isEmpty && _pendingMatches.isEmpty)
            _buildMessageState(
              icon: Icons.forum_outlined,
              title: 'Chưa có cuộc trò chuyện nào',
              actionLabel: 'Khám phá',
              onAction: () => Navigator.of(context).pushNamed('/discover'),
            )
          else if (filteredChats.isEmpty)
            const SizedBox.shrink()
          else
            ...filteredChats.map((chat) => _buildChatTile(context, chat)),
        ],
      ),
    );

    final mainContent = widget.embedded ? SafeArea(child: body) : body;

    final stackBody = Stack(
      children: [
        mainContent,
        Positioned(
          bottom: widget.embedded ? 100 : 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AskBondyBottomSheet(
                  onSubmit: (msg) {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(
                      '/bondy-ai',
                      arguments: {'initialMessage': msg},
                    ).then((_) => _loadAll(silent: true));
                  },
                ),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 4,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: BondyColors.primaryGradient,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final scaffold = Scaffold(
      backgroundColor: BondyColors.background,
      appBar: widget.embedded
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Tin nhắn'),
            ),
      body: stackBody,
    );

    return scaffold;
  }

  Widget _buildHeaderTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Danh sách kết đôi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: Color(0xFF0F172A), size: 24),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng lọc đang được phát triển')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người ấy...',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
              ),
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalPendingList() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingMatches.length,
        itemBuilder: (context, index) {
          final match = _pendingMatches[index];
          final bool hasGradient = index % 3 != 2;
          final bool isOnline = index % 3 == 0;

          final avatarContainer = Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasGradient
                  ? const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFEA2A5A)],
                    )
                  : null,
              color: hasGradient ? null : const Color(0xFFE2E8F0),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundImage: match.otherUserPhoto != null
                    ? NetworkImage(match.otherUserPhoto!)
                    : null,
                child: match.otherUserPhoto == null
                    ? Text(match.otherUserName[0].toUpperCase())
                    : null,
              ),
            ),
          );

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(
                '/match-confirm',
                arguments: {'matchId': match.id},
              ).then((_) => _loadAll(silent: true)),
              child: Column(
                children: [
                  Stack(
                    children: [
                      avatarContainer,
                      if (isOnline)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    match.otherUserName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isNewConnection(ChatMatch chat) {
    if (chat.lastMessage == null) return true;
    if (!chat.lastMessage!.isMine && DateTime.now().difference(chat.updatedAt).inHours < 24) {
      return true;
    }
    return false;
  }

  String _formatRelativeTime(DateTime value) {
    final now = DateTime.now();
    final difference = now.difference(value);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày';
    } else {
      final hour = value.hour.toString().padLeft(2, '0');
      final minute = value.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
  }

  Widget _buildChatTile(BuildContext context, ChatMatch chat) {
    final displayName = chat.otherUser.displayName.isEmpty
        ? 'Bondy user'
        : chat.otherUser.displayName;
    
    final bool isNewChat = chat.lastMessage == null || chat.lastMessage!.content.isEmpty;
    final int seed = chat.id.hashCode;
    final String icebreaker = AIPromptsConfig.icebreakers[seed % AIPromptsConfig.icebreakers.length];
    
    final bool isUnread = chat.unreadCount > 0;
    final bool showNewBadge = _isNewConnection(chat);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: _buildAvatar(chat.otherUser.photo, displayName, showNewBadge: showNewBadge),
        title: Text(
          displayName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: isNewChat
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.local_florist, size: 14, color: BondyColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Gợi ý mở lời: "$icebreaker"',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: BondyColors.primary.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  chat.lastMessage!.content,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                    color: isUnread ? const Color(0xFF0F172A) : BondyColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatRelativeTime(chat.lastMessage?.createdAt ?? chat.updatedAt),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                color: showNewBadge 
                    ? const Color(0xFFEF4444)
                    : (isUnread ? const Color(0xFF0F172A) : BondyColors.textHint),
              ),
            ),
            if (isUnread) ...[
              const SizedBox(height: 6),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onTap: () => Navigator.of(context).pushNamed(
          '/chat',
          arguments: {
            'chatId': chat.id,
            'matchId': chat.matchId,
            'otherUserId': chat.otherUser.id,
            'name': displayName,
            'photo': chat.otherUser.photo,
            'isOnline': chat.otherUser.isOnline,
            'lastSeenAt': chat.otherUser.lastSeenAt,
            'presenceStatus': chat.otherUser.presenceStatus,
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

  Widget _buildAvatar(String? photo, String displayName, {bool showNewBadge = false}) {
    Widget avatar;
    if (photo != null && photo.startsWith('http')) {
      avatar = CircleAvatar(radius: 26, backgroundImage: NetworkImage(photo));
    } else {
      final initial = displayName.trim().isEmpty
          ? 'B'
          : displayName.trim()[0].toUpperCase();
      avatar = CircleAvatar(
        radius: 26,
        backgroundColor: BondyColors.primaryLight,
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      );
    }

    if (!showNewBadge) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              'Mới',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
