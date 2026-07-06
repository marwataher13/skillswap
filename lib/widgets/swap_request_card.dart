import 'package:flutter/material.dart';
import '../models/swap_request_model.dart';
import '../theme/app_theme.dart';
import 'swap_status_badge.dart';

class SwapRequestCard extends StatelessWidget {
  final SwapRequest request;
  final bool isSent;
  final VoidCallback onTap;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;
  final Future<void> Function()? onCancel;

  const SwapRequestCard({
    super.key,
    required this.request,
    required this.isSent,
    required this.onTap,
    this.onAccept,
    this.onReject,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final user = isSent ? request.receiver : request.sender;
    final name = user?.name ?? (isSent ? 'Receiver' : 'Sender');
    final picture = user?.profilePicture;
    final isPending = request.status == 'pending';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(name: name, picture: picture, primaryLight: c.primaryLight, primary: c.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.trustScore != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                              const SizedBox(width: 3),
                              Text(
                                user!.trustScore!,
                                style: AppTextStyles.labelSmall.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SwapStatusBadge(status: request.status),
                ],
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: c.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, size: 14, color: c.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Requested Skill: ${request.requestedSkill ?? "General Swap"}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (request.cleanMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    request.cleanMessage,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: c.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              if (request.createdAt != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: c.textHint),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(request.createdAt!),
                      style: AppTextStyles.labelSmall.copyWith(color: c.textHint, fontSize: 11),
                    ),
                  ],
                ),
              ],

              if (isPending) ...[
                const SizedBox(height: 14),
                if (!isSent)
                  _ReceivedActions(onAccept: onAccept, onReject: onReject, errorColor: c.error)
                else
                  _SentActions(onCancel: onCancel, textSecondary: c.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? picture;
  final Color primaryLight;
  final Color primary;

  const _Avatar({
    required this.name,
    required this.primaryLight,
    required this.primary,
    this.picture,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2).map((w) {
      return w.isNotEmpty ? w[0].toUpperCase() : '';
    }).join();

    if (picture != null && picture!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: primaryLight,
        backgroundImage: NetworkImage(picture!),
        onBackgroundImageError: (_, _) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: primaryLight,
      child: Text(
        initials,
        style: AppTextStyles.labelMedium.copyWith(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReceivedActions extends StatefulWidget {
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;
  final Color errorColor;

  const _ReceivedActions({
    this.onAccept,
    this.onReject,
    required this.errorColor,
  });

  @override
  State<_ReceivedActions> createState() => _ReceivedActionsState();
}

class _ReceivedActionsState extends State<_ReceivedActions> {
  bool _acceptLoading = false;
  bool _rejectLoading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _rejectLoading || _acceptLoading
                ? null
                : () async {
                    setState(() => _rejectLoading = true);
                    await widget.onReject?.call();
                    if (mounted) setState(() => _rejectLoading = false);
                  },
            icon: _rejectLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.close_rounded, size: 16),
            label: const Text('Reject', overflow: TextOverflow.visible, softWrap: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.errorColor,
              side: BorderSide(color: widget.errorColor.withValues(alpha: 0.5)),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _acceptLoading || _rejectLoading
                ? null
                : () async {
                    setState(() => _acceptLoading = true);
                    await widget.onAccept?.call();
                    if (mounted) setState(() => _acceptLoading = false);
                  },
            icon: _acceptLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, size: 16),
            label: const Text('Accept', overflow: TextOverflow.visible, softWrap: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SentActions extends StatefulWidget {
  final Future<void> Function()? onCancel;
  final Color textSecondary;

  const _SentActions({this.onCancel, required this.textSecondary});

  @override
  State<_SentActions> createState() => _SentActionsState();
}

class _SentActionsState extends State<_SentActions> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                await widget.onCancel?.call();
                if (mounted) setState(() => _loading = false);
              },
        icon: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cancel_outlined, size: 16),
        label: const Text('Cancel Request', overflow: TextOverflow.visible, softWrap: false),
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.textSecondary,
          side: BorderSide(color: widget.textSecondary.withValues(alpha: 0.4)),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}
