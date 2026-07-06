import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/swap_request_model.dart';
import '../models/time_slot_model.dart';
import '../providers/profile_provider.dart';
import '../services/swap_request_service.dart';
import '../services/time_slot_service.dart';
import '../theme/app_theme.dart';
import '../widgets/swap_status_badge.dart';

class SwapRequestDetailsScreen extends StatefulWidget {
  final int requestId;

  const SwapRequestDetailsScreen({super.key, required this.requestId});

  @override
  State<SwapRequestDetailsScreen> createState() => _SwapRequestDetailsScreenState();
}

class _SwapRequestDetailsScreenState extends State<SwapRequestDetailsScreen> {
  final _service = SwapRequestService();

  SwapRequest? _request;
  bool _isLoading = true;
  String? _error;

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
      final req = await _service.fetchById(widget.requestId);
      if (mounted) {
        setState(() {
          _request = req;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: const BackButton(),
        title: Text('Request Details', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: _buildBody(c),
    );
  }

  Widget _buildBody(AppColorsExtension c) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: c.error),
              const SizedBox(height: 16),
              Text(_error!, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final req = _request!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusCard(status: req.status),
          const SizedBox(height: 16),
          if (req.sender != null) _UserCard(label: 'Sender', user: req.sender!),
          const SizedBox(height: 12),
          if (req.receiver != null) _UserCard(label: 'Receiver', user: req.receiver!),
          const SizedBox(height: 16),

          Text('Requested Skill', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Icon(Icons.school_rounded, color: c.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    req.requestedSkill ?? 'General Swap',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (req.cleanMessage.isNotEmpty) ...[
            Text('Message', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: AppShadows.card,
              ),
              child: Text(req.cleanMessage, style: AppTextStyles.bodyLarge.copyWith(height: 1.5)),
            ),
            const SizedBox(height: 16),
          ],

          _TimestampCard(request: req),
          const SizedBox(height: 24),
          _SuggestMeetingSection(
            receiverId: req.senderId == context.read<ProfileProvider>().profile.id
                ? req.receiverId
                : req.senderId,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Text('Status', style: AppTextStyles.labelMedium),
          const Spacer(),
          SwapStatusBadge(status: status),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String label;
  final SwapRequestUser user;
  const _UserCard({required this.label, required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final initials = user.name.trim().split(' ').take(2).map((w) {
      return w.isNotEmpty ? w[0].toUpperCase() : '';
    }).join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: c.primaryLight,
            backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                ? NetworkImage(user.profilePicture!)
                : null,
            child: user.profilePicture == null || user.profilePicture!.isEmpty
                ? Text(
                    initials,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSmall.copyWith(color: c.textSecondary)),
                const SizedBox(height: 2),
                Text(user.name, style: AppTextStyles.titleMedium),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: AppTextStyles.bodyMedium.copyWith(color: c.textHint),
                  ),
              ],
            ),
          ),
          if (user.trustScore != null)
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 3),
                Text(user.trustScore!, style: AppTextStyles.labelSmall),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimestampCard extends StatelessWidget {
  final SwapRequest request;
  const _TimestampCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline', style: AppTextStyles.labelMedium),
          const SizedBox(height: 12),
          if (request.createdAt != null)
            _TimeRow(icon: Icons.send_rounded, label: 'Sent', time: request.createdAt!, primary: c.primary),
          if (request.updatedAt != null && request.updatedAt != request.createdAt) ...[
            const SizedBox(height: 8),
            _TimeRow(icon: Icons.update_rounded, label: 'Updated', time: request.updatedAt!, primary: c.primary),
          ],
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime time;
  final Color primary;

  const _TimeRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${time.day}/${time.month}/${time.year}  ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Icon(icon, size: 14, color: primary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.labelSmall),
        Text(formatted, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _SuggestMeetingSection extends StatefulWidget {
  final int receiverId;
  const _SuggestMeetingSection({required this.receiverId});

  @override
  State<_SuggestMeetingSection> createState() => _SuggestMeetingSectionState();
}

class _SuggestMeetingSectionState extends State<_SuggestMeetingSection> {
  final _service = TimeSlotService();
  bool _isLoading = false;
  List<TimeSlotModel>? _suggestions;
  String? _error;

  Future<void> _fetchSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _suggestions = null;
    });

    try {
      final res = await _service.suggestMeetingTimes(widget.receiverId);
      if (mounted) {
        setState(() {
          _suggestions = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
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

  String _calcDuration(String start, String end) {
    try {
      final startParts = start.split(':');
      final endParts = end.split(':');
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final diff = endMin - startMin;
      if (diff <= 0) return '0 min';
      final h = diff ~/ 60;
      final m = diff % 60;
      if (h == 0) return '$m mins';
      if (m == 0) return '$h hr${h > 1 ? 's' : ''}';
      return '$h hr${h > 1 ? 's' : ''} $m mins';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchSuggestions,
            icon: const Icon(Icons.psychology_rounded, size: 20),
            label: const Text('Suggest Meeting Time'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (_isLoading) ...[
          const SizedBox(height: 16),
          Center(
            child: CircularProgressIndicator(color: c.primary),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: c.error.withValues(alpha: 0.2)),
            ),
            child: Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(color: c.error),
            ),
          ),
        ],
        if (_suggestions != null) ...[
          const SizedBox(height: 16),
          Text('Suggested Common Times', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          if (_suggestions!.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: c.border),
              ),
              child: Center(
                child: Text(
                  'No common available time slots found.',
                  style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions!.length,
              itemBuilder: (context, idx) {
                final slot = _suggestions![idx];
                final dur = _calcDuration(slot.startTime, slot.endTime);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: AppShadows.card,
                    border: Border.all(color: c.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [c.gradientStart, c.gradientEnd]),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          slot.dayOfWeek.length >= 3
                              ? slot.dayOfWeek.substring(0, 3).toUpperCase()
                              : slot.dayOfWeek.toUpperCase(),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.dayOfWeek,
                              style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_fmt(slot.startTime)} – ${_fmt(slot.endTime)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: c.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: c.primary),
                          const SizedBox(height: 4),
                          Text(
                            dur,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}
