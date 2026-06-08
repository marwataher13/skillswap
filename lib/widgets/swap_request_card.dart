import 'package:flutter/material.dart';
import '../models/swap_request_model.dart';
import '../theme/app_theme.dart';
import 'swap_status_badge.dart';
 
class SwapRequestCard extends StatelessWidget {
  final SwapRequest request;
  final bool isSent; // true = sent tab, false = received tab
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
    final user = isSent ? request.receiver : request.sender;
    final name = user?.name ?? (isSent ? 'Receiver' : 'Sender');
    final picture = user?.profilePicture;
    final isPending = request.status == 'pending';
 
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: avatar + name + badge ──────────────────────────
              Row(
                children: [
                  _Avatar(name: name, picture: picture),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.trustScore != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                user!.trustScore!,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
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
 
              // ── Message ──────────────────────────────────────────────────
              if (request.message != null && request.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    request.message!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
 
              // ── Date ─────────────────────────────────────────────────────
              if (request.createdAt != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(request.createdAt!),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
 
              // ── Action buttons ────────────────────────────────────────────
              if (isPending) ...[
                const SizedBox(height: 14),
                if (!isSent)
                  _ReceivedActions(onAccept: onAccept, onReject: onReject)
                else
                  _SentActions(onCancel: onCancel),
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
 
// ── Avatar ────────────────────────────────────────────────────────────────────
 
class _Avatar extends StatelessWidget {
  final String name;
  final String? picture;
 
  const _Avatar({required this.name, this.picture});
 
  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2).map((w) {
      return w.isNotEmpty ? w[0].toUpperCase() : '';
    }).join();
 
    if (picture != null && picture!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: NetworkImage(picture!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
 
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        initials,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
 
// ── Received action buttons ───────────────────────────────────────────────────
 
class _ReceivedActions extends StatefulWidget {
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;
 
  const _ReceivedActions({this.onAccept, this.onReject});
 
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
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 16),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
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
 
// ── Sent action buttons ───────────────────────────────────────────────────────
 
class _SentActions extends StatefulWidget {
  final Future<void> Function()? onCancel;
 
  const _SentActions({this.onCancel});
 
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
        label: const Text('Cancel Request'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}