import 'package:flutter/material.dart';
import 'package:skillswap/models/time_slot_model.dart';
import 'package:skillswap/services/time_slot_service.dart';
import 'package:skillswap/theme/app_theme.dart';

class TimeSlotBottomSheet extends StatefulWidget {
  final TimeSlotModel? existing;
  final VoidCallback onSaved;

  const TimeSlotBottomSheet({super.key, this.existing, required this.onSaved});

  @override
  State<TimeSlotBottomSheet> createState() => _TimeSlotBottomSheetState();
}

class _TimeSlotBottomSheetState extends State<TimeSlotBottomSheet> {
  final TimeSlotService _service = TimeSlotService();

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  static final List<String> _times = List.generate(48, (i) {
    final h = (i ~/ 2).toString().padLeft(2, '0');
    final m = (i % 2 == 0) ? '00' : '30';
    return '$h:$m';
  });

  late String _selectedDay;
  late String _selectedStart;
  late String _selectedEnd;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedDay = e?.dayOfWeek ?? _days[0];
    _selectedStart = _normalizeTime(e?.startTime ?? '09:00');
    _selectedEnd = _normalizeTime(e?.endTime ?? '11:00');
  }

  String _normalizeTime(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }

  Future<void> _save() async {
    if (_times.indexOf(_selectedEnd) <= _times.indexOf(_selectedStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('End time must be after start time'),
          backgroundColor: context.appColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final errorColor = context.appColors.error;
    final successColor = context.appColors.success;

    try {
      if (_isEdit) {
        await _service.updateTimeSlot(
          id: widget.existing!.id,
          dayOfWeek: _selectedDay,
          startTime: _selectedStart,
          endTime: _selectedEnd,
        );
      } else {
        await _service.createTimeSlot(
          dayOfWeek: _selectedDay,
          startTime: _selectedStart,
          endTime: _selectedEnd,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Time slot updated!' : 'Time slot added!'),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleanMsg.isNotEmpty ? cleanMsg : 'Failed to save. Please try again.'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _fmtDisplay(String t) {
    try {
      final parts = t.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1];
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
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [c.gradientStart, c.gradientEnd]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isEdit ? 'Edit Time Slot' : 'Add Time Slot', style: AppTextStyles.headlineMedium),
                    Text('Set your availability', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            _label('Day of Week', c),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                itemBuilder: (ctx, i) {
                  final day = _days[i];
                  final sel = _selectedDay == day;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: sel
                            ? LinearGradient(colors: [c.gradientStart, c.gradientEnd])
                            : null,
                        color: sel ? null : c.inputFill,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: sel ? Colors.transparent : c.border),
                      ),
                      child: Center(
                        child: Text(
                          day.substring(0, 3),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: sel ? Colors.white : c.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Start Time', c),
                      const SizedBox(height: 8),
                      _timeDropdown(value: _selectedStart, onChanged: (v) => setState(() => _selectedStart = v!), c: c),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text('–', style: AppTextStyles.headlineMedium.copyWith(color: c.textHint)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('End Time', c),
                      const SizedBox(height: 8),
                      _timeDropdown(value: _selectedEnd, onChanged: (v) => setState(() => _selectedEnd = v!), c: c),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: c.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: c.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${_fmtDisplay(_selectedStart)}  →  ${_fmtDisplay(_selectedEnd)}',
                    style: AppTextStyles.labelMedium.copyWith(color: c.mochaBean, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Save Changes' : 'Add Time Slot'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, AppColorsExtension c) => Text(
    text,
    style: AppTextStyles.labelMedium.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
  );

  Widget _timeDropdown({
    required String value,
    required void Function(String?) onChanged,
    required AppColorsExtension c,
  }) {
    final safeValue = _times.contains(value) ? value : _times[0];
    return Container(
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textSecondary),
        dropdownColor: c.surface,
        items: _times
            .map((t) => DropdownMenuItem(value: t, child: Text(_fmtDisplay(t), style: AppTextStyles.bodyMedium)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
