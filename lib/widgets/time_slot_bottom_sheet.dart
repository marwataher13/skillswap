import 'package:flutter/material.dart';
import 'package:skillswap/models/time_slot_model.dart';
import 'package:skillswap/services/time_slot_service.dart';
import 'package:skillswap/theme/app_theme.dart';

class TimeSlotBottomSheet extends StatefulWidget {
  final TimeSlotModel? existing; // null = add, non-null = edit
  final VoidCallback onSaved;

  const TimeSlotBottomSheet({super.key, this.existing, required this.onSaved});

  @override
  State<TimeSlotBottomSheet> createState() => _TimeSlotBottomSheetState();
}

class _TimeSlotBottomSheetState extends State<TimeSlotBottomSheet> {
  final TimeSlotService _service = TimeSlotService();

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Start/end time options: 00:00 – 23:30 in 30-min steps
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

  /// Strip seconds from "09:00:00" → "09:00"
  String _normalizeTime(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }

  Future<void> _save() async {
    // Validate end > start
    if (_times.indexOf(_selectedEnd) <= _times.indexOf(_selectedStart)) {
      _showError('End time must be after start time');
      return;
    }

    setState(() => _isSaving = true);
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
      _showSuccess(_isEdit ? 'Time slot updated!' : 'Time slot added!');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    ),
  );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    ),
  );

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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'Edit Time Slot' : 'Add Time Slot',
                      style: AppTextStyles.headlineMedium,
                    ),
                    Text(
                      'Set your availability',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Day selector
            _label('Day of Week'),
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
                            ? const LinearGradient(
                                colors: [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd,
                                ],
                              )
                            : null,
                        color: sel ? null : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                        border: Border.all(
                          color: sel ? Colors.transparent : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          day.substring(0, 3),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: sel ? Colors.white : AppColors.textSecondary,
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

            // Time row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Start Time'),
                      const SizedBox(height: 8),
                      _timeDropdown(
                        value: _selectedStart,
                        onChanged: (v) => setState(() => _selectedStart = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    '–',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('End Time'),
                      const SizedBox(height: 8),
                      _timeDropdown(
                        value: _selectedEnd,
                        onChanged: (v) => setState(() => _selectedEnd = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Duration preview
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_fmtDisplay(_selectedStart)}  →  ${_fmtDisplay(_selectedEnd)}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.mochaBean,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_isEdit ? 'Save Changes' : 'Add Time Slot'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.labelMedium.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _timeDropdown({
    required String value,
    required void Function(String?) onChanged,
  }) {
    // Ensure value is in list
    final safeValue = _times.contains(value) ? value : _times[0];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
        dropdownColor: AppColors.surface,
        items: _times
            .map(
              (t) => DropdownMenuItem(
                value: t,
                child: Text(_fmtDisplay(t), style: AppTextStyles.bodyMedium),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
