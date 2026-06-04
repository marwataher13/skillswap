import 'package:flutter/material.dart';
import 'package:skillswap/models/time_slot_model.dart';
import 'package:skillswap/services/time_slot_service.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'package:skillswap/widgets/time_slot_card.dart';
import 'package:skillswap/widgets/time_slot_bottom_sheet.dart';

/// Drop this widget anywhere in your scroll view.
/// It is self-contained: manages its own state, loads data independently.
class TimeSlotSection extends StatefulWidget {
  const TimeSlotSection({super.key});

  @override
  State<TimeSlotSection> createState() => _TimeSlotSectionState();
}

class _TimeSlotSectionState extends State<TimeSlotSection> {
  final TimeSlotService _service = TimeSlotService();

  List<TimeSlotModel> _slots = [];
  bool _isLoading = true;
  String? _error;

  // Track which slot ids are currently toggling
  final Set<int> _toggling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final slots = await _service.getMyTimeSlots();
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle(TimeSlotModel slot) async {
    if (_toggling.contains(slot.id)) return;

    // Optimistic update
    setState(() {
      _toggling.add(slot.id);
      _slots = _slots
          .map(
            (s) =>
                s.id == slot.id ? s.copyWith(isAvailable: !s.isAvailable) : s,
          )
          .toList();
    });

    try {
      final updated = await _service.toggleAvailability(slot.id);
      if (!mounted) return;
      setState(() {
        _slots = _slots.map((s) => s.id == updated.id ? updated : s).toList();
      });
    } catch (_) {
      // Revert optimistic update on failure
      if (!mounted) return;
      setState(() {
        _slots = _slots
            .map(
              (s) => s.id == slot.id
                  ? s.copyWith(isAvailable: slot.isAvailable)
                  : s,
            )
            .toList();
      });
      _showError('Failed to update availability');
    } finally {
      if (mounted) setState(() => _toggling.remove(slot.id));
    }
  }

  Future<void> _delete(TimeSlotModel slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        backgroundColor: AppColors.surface,
        title: Text('Delete Slot', style: AppTextStyles.headlineMedium),
        content: Text(
          'Remove "${slot.dayOfWeek} ${slot.startTime}–${slot.endTime}"?',
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
    if (confirmed != true) return;

    try {
      await _service.deleteTimeSlot(slot.id);
      if (!mounted) return;
      setState(() => _slots = _slots.where((s) => s.id != slot.id).toList());
      _showSuccess('Time slot removed');
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to delete. Try again.');
    }
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimeSlotBottomSheet(onSaved: _load),
    );
  }

  void _openEdit(TimeSlotModel slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimeSlotBottomSheet(existing: slot, onSaved: _load),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Time Slots',
                      style: AppTextStyles.titleMedium,
                    ),
                    Text(
                      'Your weekly availability',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
              // Add button
              GestureDetector(
                onTap: _openAdd,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.button,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Content ─────────────────────────────────────────────
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildShimmer();
    if (_error != null) return _buildError();
    if (_slots.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildShimmer() {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => _ShimmerCard(),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Could not load time slots',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            TextButton(
              onPressed: _load,
              child: Text(
                'Retry',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.border.withOpacity(0.6),
            style: BorderStyle.solid,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No time slots yet',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Add your availability so others\ncan schedule with you.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 160,
              child: ElevatedButton.icon(
                onPressed: _openAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Slot'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
        physics: const BouncingScrollPhysics(),
        itemCount: _slots.length,
        itemBuilder: (_, i) {
          final slot = _slots[i];
          return TimeSlotCard(
            slot: slot,
            isToggling: _toggling.contains(slot.id),
            onToggle: () => _toggle(slot),
            onEdit: () => _openEdit(slot),
            onDelete: () => _delete(slot),
          );
        },
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 168,
        height: 190,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.surfaceVariant,
            AppColors.surface,
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}
