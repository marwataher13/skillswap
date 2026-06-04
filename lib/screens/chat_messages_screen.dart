import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skillswap/models/conversation_model.dart';
import 'package:skillswap/models/message_model.dart';
import 'package:skillswap/services/chat_service.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'package:skillswap/widgets/message_bubble.dart';
import 'package:skillswap/widgets/chat_input_field.dart';

class ChatMessagesScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ChatMessagesScreen({super.key, required this.conversation});

  @override
  State<ChatMessagesScreen> createState() => _ChatMessagesScreenState();
}

class _ChatMessagesScreenState extends State<ChatMessagesScreen> {
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  // Poll for new messages every 5 seconds
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollMessages(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final msgs = await _chatService.fetchMessages(widget.conversation.id);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom(animated: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Silent background poll — no loading spinner
  Future<void> _pollMessages() async {
    if (!mounted) return;
    try {
      final msgs = await _chatService.fetchMessages(widget.conversation.id);
      if (!mounted) return;
      if (msgs.length != _messages.length) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Optimistic insert
    final optimistic = MessageModel(
      id: -DateTime.now().millisecondsSinceEpoch, // temp id
      conversationId: widget.conversation.id,
      body: text,
      isFromMe: true,
      sentAt: DateTime.now(),
    );
    setState(() {
      _messages = [..._messages, optimistic];
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final sent = await _chatService.sendMessage(
        conversationId: widget.conversation.id,
        body: text,
      );
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map((m) => m.id == optimistic.id ? sent : m)
            .toList();
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Remove optimistic message on failure
      setState(() {
        _messages = _messages.where((m) => m.id != optimistic.id).toList();
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      );
    }
  }

  Future<void> _deleteMessage(MessageModel msg) async {
    if (!msg.isFromMe) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        backgroundColor: AppColors.surface,
        title: Text('Delete Message', style: AppTextStyles.headlineMedium),
        content: Text(
          'Are you sure you want to delete this message?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(90, 40),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await _chatService.deleteMessage(
        conversationId: widget.conversation.id,
        messageId: msg.id,
      );
      if (!mounted) return;
      setState(
        () => _messages = _messages.where((m) => m.id != msg.id).toList(),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete message.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.conversation.otherUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(user),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          ChatInputField(onSend: _sendMessage, isSending: _isSending),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(OtherUser user) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.divider,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar
          _buildSmallAvatar(user),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Tap for info',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () {
            // Future: info / block / report
          },
        ),
      ],
    );
  }

  Widget _buildSmallAvatar(OtherUser user) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: user.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                user.avatarUrl!,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsWidget(user),
              ),
            )
          : _initialsWidget(user),
    );
  }

  Widget _initialsWidget(OtherUser user) {
    return Center(
      child: Text(
        user.initials,
        style: AppTextStyles.labelMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text('Failed to load messages', style: AppTextStyles.titleMedium),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
            ),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.waving_hand_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text('Say hello!', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Start the conversation below.',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      itemCount: _buildItems().length,
      itemBuilder: (context, index) => _buildItems()[index],
    );
  }

  /// Build a flat list of widgets: DateSeparators + MessageBubbles
  List<Widget> _buildItems() {
    final items = <Widget>[];
    DateTime? lastDate;

    for (final msg in _messages) {
      final msgDate = DateTime(
        msg.sentAt.year,
        msg.sentAt.month,
        msg.sentAt.day,
      );
      if (lastDate == null || msgDate != lastDate) {
        items.add(DateSeparator(date: msg.sentAt));
        lastDate = msgDate;
      }
      items.add(
        MessageBubble(
          message: msg,
          onLongPress: msg.isFromMe ? () => _deleteMessage(msg) : null,
        ),
      );
    }
    return items;
  }
}
