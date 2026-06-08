import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
 
class SwapStatusBadge extends StatelessWidget {
  final String status;
 
  const SwapStatusBadge({super.key, required this.status});
 
  @override
  Widget build(BuildContext context) {
    final cfg = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: cfg.fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 12, color: cfg.fg),
          const SizedBox(width: 4),
          Text(
            cfg.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: cfg.fg,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
 
  _BadgeConfig _config(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return _BadgeConfig(
          label: 'Accepted',
          icon: Icons.check_circle_rounded,
          fg: const Color(0xFF16A34A),
          bg: const Color(0xFFDCFCE7),
        );
      case 'rejected':
        return _BadgeConfig(
          label: 'Rejected',
          icon: Icons.cancel_rounded,
          fg: AppColors.error,
          bg: AppColors.error.withValues(alpha: 0.1),
        );
      case 'cancelled':
        return _BadgeConfig(
          label: 'Cancelled',
          icon: Icons.remove_circle_rounded,
          fg: AppColors.textSecondary,
          bg: AppColors.surfaceVariant,
        );
      default: // pending
        return _BadgeConfig(
          label: 'Pending',
          icon: Icons.access_time_rounded,
          fg: const Color(0xFFD97706),
          bg: const Color(0xFFFEF3C7),
        );
    }
  }
}
 
class _BadgeConfig {
  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
 
  const _BadgeConfig({
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
  });
}