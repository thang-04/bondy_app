import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_client.dart';
import '../../services/chat_service.dart';
import '../../services/match_service.dart';
import '../../theme/app_theme.dart';
import '../../core/ai_prompts_config.dart';
import '../../widgets/chat/ask_bondy_bottom_sheet.dart';

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
    final filteredChats = _chats.where((chat) {
      final name = chat.otherUser.displayName.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    final body = RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, widget.embedded ? 16 : 8, 16, widget.embedded ? 110 : 24),
        children: [
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
          right: 16,
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
                      '/chatbot',
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
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
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
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingMatches.length,
        itemBuilder: (context, index) {
          final match = _pendingMatches[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(
                '/match-confirm',
                arguments: {'matchId': match.id},
              ).then((_) => _loadAll(silent: true)),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA2A5A)],
                      ),
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



  Widget _buildChatTile(BuildContext context, ChatMatch chat) {
    final displayName = chat.otherUser.displayName.isEmpty
        ? 'Bondy user'
        : chat.otherUser.displayName;
    
    final bool isNewChat = chat.lastMessage == null || chat.lastMessage!.content.isEmpty;
    final int seed = chat.id.hashCode;
    final String icebreaker = AIPromptsConfig.icebreakers[seed % AIPromptsConfig.icebreakers.length];

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.lastMessage!.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: BondyColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_florist, size: 12, color: BondyColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Gợi ý hâm nóng: "$icebreaker"',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: BondyColors.primary.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
