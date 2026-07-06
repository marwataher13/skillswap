import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/conversation_model.dart';
import 'package:skillswap/models/message_model.dart';
import 'package:skillswap/providers/chat_provider.dart';
import 'package:skillswap/services/chat_service.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'package:skillswap/widgets/message_bubble.dart';
import 'package:skillswap/widgets/chat_input_field.dart';
import 'package:skillswap/screens/profile_view_screen.dart';

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
  List<Widget> _displayItems = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().markConversationRead(widget.conversation.id);
      }
    });
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

  void _updateDisplayItems() {
    final items = <Widget>[];
    DateTime? lastDate;

    for (final msg in _messages) {
      final msgDate = DateTime(msg.sentAt.year, msg.sentAt.month, msg.sentAt.day);
      if (lastDate == null || msgDate != lastDate) {
        items.add(DateSeparator(date: msg.sentAt));
        lastDate = msgDate;
      }
      items.add(
        MessageBubble(
          key: ValueKey(msg.id),
          message: msg,
          onLongPress: msg.isFromMe ? () => _deleteMessage(msg) : null,
        ),
      );
    }
    _displayItems = items;
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
        _updateDisplayItems();
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

  Future<void> _pollMessages() async {
    if (!mounted) return;
    if (_isSending || _messages.any((m) => m.id < 0)) return;
    try {
      final msgs = await _chatService.fetchMessages(widget.conversation.id);
      if (!mounted) return;
      if (_isSending || _messages.any((m) => m.id < 0)) return;
      if (msgs.length != _messages.length) {
        setState(() {
          _messages = msgs;
          _updateDisplayItems();
        });
        _scrollToBottom();
        if (mounted) {
          context.read<ChatProvider>().markConversationRead(widget.conversation.id);
        }
      }
    } catch (_) {}
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final optimistic = MessageModel(
      id: -DateTime.now().millisecondsSinceEpoch,
      conversationId: widget.conversation.id,
      body: text,
      isFromMe: true,
      sentAt: DateTime.now(),
    );
    setState(() {
      _messages = [..._messages, optimistic];
      _updateDisplayItems();
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
        final index = _messages.indexWhere((m) => m.id == optimistic.id);
        if (index != -1) {
          _messages[index] = sent;
        } else {
          _messages.add(sent);
        }
        _updateDisplayItems();
        _isSending = false;
      });
      context.read<ChatProvider>().loadConversations(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages = _messages.where((m) => m.id != optimistic.id).toList();
        _updateDisplayItems();
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message. Please try again.'),
          backgroundColor: context.appColors.error,
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
    final c = context.appColors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dc = ctx.appColors;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          backgroundColor: dc.surface,
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
                style: AppTextStyles.labelMedium.copyWith(color: dc.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dc.error,
                minimumSize: const Size(90, 40),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    try {
      await _chatService.deleteMessage(
        conversationId: widget.conversation.id,
        messageId: msg.id,
      );
      if (!mounted) return;
      setState(() {
        _messages = _messages.where((m) => m.id != msg.id).toList();
        _updateDisplayItems();
      });
      context.read<ChatProvider>().loadConversations(silent: true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete message.'),
          backgroundColor: c.error,
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
    final c = context.appColors;
    final user = widget.conversation.otherUser;
    return Scaffold(
      backgroundColor: c.background,
      appBar: _buildAppBar(user, c),
      body: Column(
        children: [
          Expanded(child: _buildBody(c)),
          ChatInputField(onSend: _sendMessage, isSending: _isSending),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(OtherUser user, AppColorsExtension c) {
    return AppBar(
      backgroundColor: c.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: c.divider,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: c.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfileViewScreen(),
            settings: RouteSettings(arguments: user.id),
          ),
        ),
        child: Row(
          children: [
            _buildSmallAvatar(user, c),
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
                    _isLoading
                        ? 'Loading messages...'
                        : '${_messages.length} ${_messages.length == 1 ? 'message' : 'messages'}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: c.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: c.textPrimary, size: 24),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSmallAvatar(OtherUser user, AppColorsExtension c) {
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasAvatar
            ? null
            : LinearGradient(
                colors: [c.gradientStart, c.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: hasAvatar ? c.surfaceVariant : null,
      ),
      child: hasAvatar
          ? ClipOval(
              child: Image.network(
                user.avatarUrl!,
                headers: const {'ngrok-skip-browser-warning': 'true'},
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c.gradientStart, c.gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: _initialsWidget(user),
                  );
                },
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

  Widget _buildBody(AppColorsExtension c) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: c.primary, strokeWidth: 2.5),
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
              color: c.error.withValues(alpha: 0.6),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.gradientStart, c.gradientEnd],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.waving_hand_rounded, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text('Say hello!', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text('Start the conversation below.', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      itemCount: _displayItems.length,
      itemBuilder: (context, index) => _displayItems[index],
    );
  }
}
