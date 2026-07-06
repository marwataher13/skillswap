import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/conversation_model.dart';
import 'package:skillswap/providers/chat_provider.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat(ConversationModel conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatMessagesScreen(conversation: conversation),
      ),
    ).then((_) {
      if (!mounted) return;
      context.read<ChatProvider>().loadConversations(silent: true);
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.appColors;
    final chatProvider = context.watch<ChatProvider>();

    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? chatProvider.conversations
        : chatProvider.conversations.where((conv) {
            return conv.otherUser.name.toLowerCase().contains(query) ||
                (conv.lastMessage?.body.toLowerCase().contains(query) ?? false);
          }).toList();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            if (_isSearchOpen) _buildSearchBar(),
            Expanded(child: _buildBody(c, chatProvider.isLoading, chatProvider.error, filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                key: ValueKey(_isSearchOpen),
                color: c.textPrimary,
                size: 24,
              ),
            ),
            onPressed: _toggleSearch,
          ),
          Expanded(
            child: Text('Chats', textAlign: TextAlign.center, style: AppTextStyles.headlineMedium),
          ),
          IconButton(
            icon: Icon(Icons.edit_square, color: c.textPrimary, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Start new conversation coming soon!'),
                  backgroundColor: c.primary,
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

  Widget _buildBody(
    AppColorsExtension c,
    bool isLoading,
    String? error,
    List<ConversationModel> filtered,
  ) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2.5));
    }
    if (error != null) return _buildError(c, error);
    final isSearchActive = _isSearchOpen && _searchController.text.trim().isNotEmpty;
    if (filtered.isEmpty) return _buildEmpty(c, isSearchActive);
    return _buildList(c, filtered);
  }

  Widget _buildError(AppColorsExtension c, String errorMsg) {
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
                color: c.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 32, color: c.error),
            ),
            const SizedBox(height: 20),
            Text('Could not load chats', style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              errorMsg.isNotEmpty ? errorMsg : 'Check your connection and try again.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<ChatProvider>().loadConversations(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension c, bool isSearchActive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.gradientStart, c.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearchActive ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearchActive ? 'No results found' : 'No conversations yet',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearchActive
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

  Widget _buildList(AppColorsExtension c, List<ConversationModel> filtered) {
    return RefreshIndicator(
      color: c.primary,
      onRefresh: () => context.read<ChatProvider>().loadConversations(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: filtered.length,
        itemBuilder: (context, index) => ChatCard(
          conversation: filtered[index],
          onTap: () => _openChat(filtered[index]),
        ),
      ),
    );
  }
}
