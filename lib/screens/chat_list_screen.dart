import 'package:flutter/material.dart';
import 'package:skillswap/models/conversation_model.dart';
import 'package:skillswap/services/chat_service.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'package:skillswap/widgets/chat_card.dart';
import 'package:skillswap/screens/chat_messages_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  List<ConversationModel> _conversations = [];
  List<ConversationModel> _filtered = [];
  bool _isLoading = true;
  String? _error;
  bool _isSearchOpen = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _chatService.fetchConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _filtered = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _conversations
          : _conversations
                .where(
                  (c) =>
                      c.otherUser.name.toLowerCase().contains(query) ||
                      (c.lastMessage?.body.toLowerCase().contains(query) ??
                          false),
                )
                .toList();
    });
  }

  void _openChat(ConversationModel conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatMessagesScreen(conversation: conversation),
      ),
    ).then((_) => _loadConversations()); // Refresh unread counts on return
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) {
        _searchController.clear();
        _filtered = _conversations;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isSearchOpen) _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          // Search icon
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                key: ValueKey(_isSearchOpen),
                color: AppColors.textPrimary,
                size: 24,
              ),
            ),
            onPressed: _toggleSearch,
          ),

          // Centered title
          Expanded(
            child: Text(
              'Chats',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium,
            ),
          ),

          // New conversation icon (placeholder; wire to a user-search flow)
          IconButton(
            icon: const Icon(
              Icons.edit_square,
              color: AppColors.textPrimary,
              size: 24,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Start new conversation coming soon!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: _searchController.clear,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_filtered.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Could not load chats',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadConversations,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final isSearchEmpty =
        _isSearchOpen && _searchController.text.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearchEmpty
                    ? Icons.search_off_rounded
                    : Icons.chat_bubble_outline_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearchEmpty ? 'No results found' : 'No conversations yet',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearchEmpty
                  ? 'Try a different search term'
                  : 'Chats will appear here once a swap\nrequest is accepted.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          return ChatCard(
            conversation: _filtered[index],
            onTap: () => _openChat(_filtered[index]),
          );
        },
      ),
    );
  }
}
