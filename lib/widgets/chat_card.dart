import 'package:flutter/material.dart';
import 'package:skillswap/models/conversation_model.dart';
import 'package:skillswap/theme/app_theme.dart';

class ChatCard extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const ChatCard({super.key, required this.conversation, required this.onTap});

  String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(localDt.year, localDt.month, localDt.day);
    final diff = today.difference(msgDate).inDays;

    if (diff == 0) {
      final h = localDt.hour.toString().padLeft(2, '0');
      final m = localDt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[localDt.weekday - 1];
    }
    return '${localDt.day}/${localDt.month}/${localDt.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final user = conversation.otherUser;
    final last = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.chatCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          splashColor: c.primaryLight.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _buildAvatar(user, c),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (last != null && last.isFromMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.done_all_rounded, size: 14, color: c.primary),
                            ),
                          Expanded(
                            child: Text(
                              last?.body ?? 'No messages yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                color: hasUnread ? c.textPrimary : c.textSecondary,
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
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      last != null ? _formatTime(last.sentAt) : '',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: hasUnread ? c.primary : c.textHint,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (hasUnread)
                      Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 22),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(OtherUser user, AppColorsExtension c) {
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
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
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _gradientFallback(
                      c: c,
                      child: _initialsFallback(user),
                    ),
                  ),
                )
              : _initialsFallback(user),
        ),
      ],
    );
  }

  Widget _gradientFallback({required AppColorsExtension c, required Widget child}) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.gradientStart, c.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }

  Widget _initialsFallback(OtherUser user) {
    return Center(
      child: Text(
        user.initials,
        style: AppTextStyles.titleMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}
