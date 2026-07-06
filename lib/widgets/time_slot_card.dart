import 'package:flutter/material.dart';
import 'package:skillswap/models/time_slot_model.dart';
import 'package:skillswap/theme/app_theme.dart';

class TimeSlotCard extends StatelessWidget {
  final TimeSlotModel slot;
  final bool isReadOnly;
  final bool isToggling;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TimeSlotCard({
    super.key,
    required this.slot,
    this.isReadOnly = false,
    this.isToggling = false,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  String get _dayAbbr {
    if (slot.dayOfWeek.length >= 3) return slot.dayOfWeek.substring(0, 3);
    return slot.dayOfWeek;
  }

  String _fmt(String t) {
    try {
      final parts = t.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1].padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $period';
    } catch (_) {
      return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final available = slot.isAvailable;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 168,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: available ? c.primary.withValues(alpha: 0.35) : c.border,
          width: available ? 1.5 : 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: available
                        ? LinearGradient(colors: [c.gradientStart, c.gradientEnd])
                        : null,
                    color: available ? null : c.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    _dayAbbr,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: available ? Colors.white : c.textHint,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (!isReadOnly) ...[
                  isToggling
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: c.primary, strokeWidth: 2),
                        )
                      : GestureDetector(
                          onTap: onToggle,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 38,
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              gradient: available
                                  ? LinearGradient(colors: [c.gradientStart, c.gradientEnd])
                                  : null,
                              color: available ? null : c.surfaceVariant,
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              alignment: available ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              slot.dayOfWeek,
              style: AppTextStyles.titleMedium.copyWith(fontSize: 15, color: c.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 13, color: c.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_fmt(slot.startTime)} – ${_fmt(slot.endTime)}',
                    style: AppTextStyles.labelSmall.copyWith(color: c.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: available
                    ? c.success.withValues(alpha: 0.12)
                    : c.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                available ? 'Available' : 'Unavailable',
                style: AppTextStyles.labelSmall.copyWith(
                  color: available ? c.success : c.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            if (!isReadOnly) ...[
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(icon: Icons.edit_outlined, label: 'Edit', onTap: onEdit!, color: c.primary),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ActionBtn(icon: Icons.delete_outline_rounded, label: 'Delete', onTap: onDelete!, color: c.error),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
