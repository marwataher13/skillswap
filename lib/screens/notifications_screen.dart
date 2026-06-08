import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  // ── Header/AppBar ────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Notifications',
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 22),
            ),
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
                          backgroundColor: AppColors.mochaBean,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to mark all read: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(LucideIcons.checkCheck, size: 16, color: AppColors.mochaBean),
                label: Text(
                  'Mark all read',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.mochaBean,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.notifications.isEmpty) {
          return _buildLoading();
        }

        if (provider.error != null && provider.notifications.isEmpty) {
          return _buildError(provider);
        }

        if (provider.notifications.isEmpty) {
          return _buildEmpty(context, provider);
        }

        return _buildList(context, provider);
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildError(NotificationProvider provider) {
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
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.wifiOff,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load notifications',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'There was a problem retrieving your updates.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.loadData,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 48),
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, NotificationProvider provider) {
    return RefreshIndicator(
      color: AppColors.primary,
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.bellOff,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No notifications yet',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will let you know when something new happens!',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, NotificationProvider provider) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refreshData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: provider.notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final notification = provider.notifications[index];
          return _buildDismissibleItem(context, provider, notification);
        },
      ),
    );
  }

  Widget _buildDismissibleItem(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notification,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          color: AppColors.error,
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
                content: Text('Deleted notification: "$title"'),
                backgroundColor: AppColors.mochaBean,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      child: _NotificationCard(
        notification: notification,
        onTap: () async {
          if (!notification.read) {
            try {
              await provider.markAsRead(notification.id);
            } catch (e) {
              debugPrint('Failed to mark read on tap: $e');
            }
          }
        },
      ),
    );
  }
}

// ── Notification Card ────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeBgColor = notification.read 
        ? AppColors.surface 
        : AppColors.surfaceVariant.withValues(alpha: 0.35);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeBgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: notification.read 
                ? AppColors.divider.withValues(alpha: 0.5) 
                : AppColors.border.withValues(alpha: 0.8),
            width: notification.read ? 1.0 : 1.5,
          ),
          boxShadow: notification.read ? null : AppShadows.subtle,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeIcon(),
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
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(notification.createdAt),
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: notification.read ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: notification.read ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read) ...[
              const SizedBox(width: 10),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.mochaBean,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (notification.type.toLowerCase()) {
      case 'chat':
      case 'message':
        iconData = LucideIcons.messageSquare;
        iconColor = AppColors.mochaBean;
        bgColor = AppColors.creamyLatte;
        break;
      case 'review':
      case 'feedback':
      case 'star':
        iconData = LucideIcons.star;
        iconColor = AppColors.caramelRoast;
        bgColor = AppColors.creamyLatte;
        break;
      case 'match':
      case 'connection':
      case 'swap':
        iconData = LucideIcons.repeat;
        iconColor = AppColors.primary;
        bgColor = AppColors.creamyLatte;
        break;
      case 'info':
      default:
        iconData = LucideIcons.info;
        iconColor = AppColors.textSecondary;
        bgColor = AppColors.creamyLatte;
        break;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
