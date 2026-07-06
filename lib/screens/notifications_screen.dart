import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/chat_provider.dart';
import '../models/notification_model.dart';
import '../models/conversation_model.dart';
import '../screens/chat_messages_screen.dart';
import '../screens/swap_request_details_screen.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().loadData();
    });
  }

  Future<void> _handleTap(NotificationModel notification) async {
    if (!notification.read) {
      try {
        await context.read<NotificationProvider>().markAsRead(notification.id);
      } catch (e) {
        debugPrint('Failed to mark read on tap: $e');
      }
    }

    if (!mounted) return;

    final type = notification.type.toLowerCase();
    final payload = notification.payload;

    if (type == 'new_message' || type == 'chat' || type == 'message') {
      final conversationId = int.tryParse(payload['conversation_id']?.toString() ?? '');
      if (conversationId != null) {
        await _openChat(conversationId, payload);
        return;
      }
    }

    if (type == 'swap_request' || type == 'new_swap' || type == 'match' ||
        type == 'connection' || type == 'swap' ||
        type == 'swap_accepted' || type == 'swap_rejected' ||
        type == 'swap_completed') {
      final requestId = int.tryParse(
        (payload['swap_request_id'] ?? payload['request_id'] ?? payload['id'] ?? '').toString(),
      );
      if (requestId != null) {
        _openSwapRequest(requestId);
        return;
      }
    }

    if (type == 'review' || type == 'new_review' || type == 'feedback' ||
        type == 'star' || type == 'review_received') {
      final userId = int.tryParse(
        (payload['reviewer_id'] ?? payload['user_id'] ?? payload['sender_id'] ?? '').toString(),
      );
      if (userId != null) {
        Navigator.pushNamed(context, '/profile', arguments: {'userId': userId});
        return;
      }
      Navigator.pushNamed(context, '/profile');
      return;
    }

    debugPrint('NotificationsScreen: no navigation target for type=$type payload=$payload');
  }

  Future<void> _openChat(int conversationId, Map<String, dynamic> payload) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = context.appColors.error;

    try {
      final chatProvider = context.read<ChatProvider>();
      ConversationModel? conversation;
      try {
        conversation = chatProvider.conversations.firstWhere((c) => c.id == conversationId);
      } catch (_) {
        conversation = null;
      }

      if (conversation == null) {
        final chatService = ChatService();
        final conversations = await chatService.fetchConversations();
        try {
          conversation = conversations.firstWhere((c) => c.id == conversationId);
        } catch (_) {
          conversation = null;
        }
      }

      conversation ??= _buildConversationStub(conversationId, payload);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatMessagesScreen(conversation: conversation!)),
      );
    } catch (e) {
      debugPrint('Failed to open chat: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Could not open chat. Please try from the Chat tab.'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  ConversationModel _buildConversationStub(int conversationId, Map<String, dynamic> payload) {
    final senderId = int.tryParse(payload['sender_id']?.toString() ?? '') ?? 0;
    final senderName = payload['sender_name']?.toString() ?? 'User';
    return ConversationModel(
      id: conversationId,
      otherUser: OtherUser(id: senderId, name: senderName),
      unreadMessagesCount: 0,
      updatedAt: DateTime.now(),
    );
  }

  void _openSwapRequest(int requestId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SwapRequestDetailsScreen(requestId: requestId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, c),
            Expanded(child: _buildBody(context, c)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppColorsExtension c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: c.textPrimary, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('Notifications', style: AppTextStyles.headlineMedium.copyWith(fontSize: 22)),
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final hasUnread = provider.notifications.any((n) => !n.read);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () async {
                  try {
                    await provider.markAllAsRead();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('All notifications marked as read'),
                          backgroundColor: c.mochaBean,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to mark all read: $e'),
                          backgroundColor: c.error,
                        ),
                      );
                    }
                  }
                },
                icon: Icon(LucideIcons.checkCheck, size: 16, color: c.mochaBean),
                label: Text(
                  'Mark all read',
                  style: AppTextStyles.labelMedium.copyWith(color: c.mochaBean, fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppColorsExtension c) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.notifications.isEmpty) {
          return _buildLoading(c);
        }
        if (provider.error != null && provider.notifications.isEmpty) {
          return _buildError(provider, c);
        }
        if (provider.notifications.isEmpty) {
          return _buildEmpty(context, provider, c);
        }
        return _buildList(context, provider, c);
      },
    );
  }

  Widget _buildLoading(AppColorsExtension c) {
    return Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2.5));
  }

  Widget _buildError(NotificationProvider provider, AppColorsExtension c) {
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
              child: Icon(LucideIcons.wifiOff, size: 32, color: c.error),
            ),
            const SizedBox(height: 20),
            Text('Failed to load notifications', style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('There was a problem retrieving your updates.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.loadData,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48), backgroundColor: c.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, NotificationProvider provider, AppColorsExtension c) {
    return RefreshIndicator(
      color: c.primary,
      onRefresh: provider.refreshData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
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
                    child: const Icon(LucideIcons.bellOff, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text('No notifications yet', style: AppTextStyles.headlineMedium.copyWith(fontSize: 20), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('We will let you know when something new happens!', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, NotificationProvider provider, AppColorsExtension c) {
    return RefreshIndicator(
      color: c.primary,
      onRefresh: provider.refreshData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: provider.notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final notification = provider.notifications[index];
          return _buildDismissibleItem(context, provider, notification, c);
        },
      ),
    );
  }

  Widget _buildDismissibleItem(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notification,
    AppColorsExtension c,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          color: c.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) async {
        final title = notification.title;
        try {
          await provider.deleteNotification(notification.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deleted: "$title"'),
                backgroundColor: c.mochaBean,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete: $e'), backgroundColor: c.error),
            );
          }
        }
      },
      child: _NotificationCard(notification: notification, onTap: () => _handleTap(notification)),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final themeBgColor = notification.read ? c.surface : c.surfaceVariant.withValues(alpha: 0.35);
    final bool hasDestination = _hasNavigationTarget(notification);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeBgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: notification.read ? c.divider.withValues(alpha: 0.5) : c.border.withValues(alpha: 0.8),
            width: notification.read ? 1.0 : 1.5,
          ),
          boxShadow: notification.read ? null : AppShadows.subtle,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeIcon(c),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 15,
                            fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
                            color: c.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(notification.createdAt),
                        style: AppTextStyles.labelSmall.copyWith(fontSize: 11, color: c.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: notification.read ? c.textSecondary : c.textPrimary,
                      fontWeight: notification.read ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!notification.read)
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: c.mochaBean, shape: BoxShape.circle),
                  ),
                if (hasDestination)
                  Icon(LucideIcons.chevronRight, size: 16, color: c.textHint),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _hasNavigationTarget(NotificationModel n) {
    final type = n.type.toLowerCase();
    final payload = n.payload;
    if ((type == 'new_message' || type == 'chat' || type == 'message') &&
        payload.containsKey('conversation_id')) {
      return true;
    }
    if ((type.contains('swap') || type == 'match' || type == 'connection') &&
        (payload.containsKey('swap_request_id') || payload.containsKey('request_id'))) {
      return true;
    }
    if (type == 'review' || type == 'new_review' || type == 'feedback' ||
        type == 'star' || type == 'review_received') {
      return true;
    }
    return false;
  }

  Widget _buildTypeIcon(AppColorsExtension c) {
    IconData iconData;
    Color iconColor;

    switch (notification.type.toLowerCase()) {
      case 'new_message':
      case 'chat':
      case 'message':
        iconData = LucideIcons.messageSquare;
        iconColor = c.mochaBean;
        break;
      case 'review':
      case 'new_review':
      case 'review_received':
      case 'feedback':
      case 'star':
        iconData = LucideIcons.star;
        iconColor = c.caramelRoast;
        break;
      case 'swap_request':
      case 'new_swap':
      case 'swap_accepted':
      case 'swap_rejected':
      case 'swap_completed':
      case 'match':
      case 'connection':
      case 'swap':
        iconData = LucideIcons.repeat;
        iconColor = c.primary;
        break;
      case 'info':
      default:
        iconData = LucideIcons.info;
        iconColor = c.textSecondary;
        break;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: c.primaryLight, shape: BoxShape.circle),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }
}
