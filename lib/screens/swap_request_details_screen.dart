import 'package:flutter/material.dart';
import '../models/swap_request_model.dart';
import '../services/swap_request_service.dart';
import '../theme/app_theme.dart';
import '../widgets/swap_status_badge.dart';
 
class SwapRequestDetailsScreen extends StatefulWidget {
  final int requestId;
 
  const SwapRequestDetailsScreen({super.key, required this.requestId});
 
  @override
  State<SwapRequestDetailsScreen> createState() =>
      _SwapRequestDetailsScreenState();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(),
        title: Text('Request Details', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }
 
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!, style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center),
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
          // ── Status card ──────────────────────────────────────────────
          _StatusCard(status: req.status),
          const SizedBox(height: 16),
 
          // ── Sender ───────────────────────────────────────────────────
          if (req.sender != null)
            _UserCard(label: 'Sender', user: req.sender!),
          const SizedBox(height: 12),
 
          // ── Receiver ─────────────────────────────────────────────────
          if (req.receiver != null)
            _UserCard(label: 'Receiver', user: req.receiver!),
          const SizedBox(height: 16),
 
          // ── Message ──────────────────────────────────────────────────
          if (req.message != null && req.message!.isNotEmpty) ...[
            Text('Message', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: AppShadows.card,
              ),
              child: Text(
                req.message!,
                style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
 
          // ── Timestamps ───────────────────────────────────────────────
          _TimestampCard(request: req),
        ],
      ),
    );
  }
}
 
// ── Status card ───────────────────────────────────────────────────────────────
 
class _StatusCard extends StatelessWidget {
  final String status;
 
  const _StatusCard({required this.status});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
 
// ── User card ─────────────────────────────────────────────────────────────────
 
class _UserCard extends StatelessWidget {
  final String label;
  final SwapRequestUser user;
 
  const _UserCard({required this.label, required this.user});
 
  @override
  Widget build(BuildContext context) {
    final initials = user.name.trim().split(' ').take(2).map((w) {
      return w.isNotEmpty ? w[0].toUpperCase() : '';
    }).join();
 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: user.profilePicture != null &&
                    user.profilePicture!.isNotEmpty
                ? NetworkImage(user.profilePicture!)
                : null,
            child: user.profilePicture == null || user.profilePicture!.isEmpty
                ? Text(
                    initials,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
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
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(user.name, style: AppTextStyles.titleMedium),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          if (user.trustScore != null)
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 3),
                Text(user.trustScore!,
                    style: AppTextStyles.labelSmall),
              ],
            ),
        ],
      ),
    );
  }
}
 
// ── Timestamps card ───────────────────────────────────────────────────────────
 
class _TimestampCard extends StatelessWidget {
  final SwapRequest request;
 
  const _TimestampCard({required this.request});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline', style: AppTextStyles.labelMedium),
          const SizedBox(height: 12),
          if (request.createdAt != null)
            _TimeRow(
              icon: Icons.send_rounded,
              label: 'Sent',
              time: request.createdAt!,
            ),
          if (request.updatedAt != null &&
              request.updatedAt != request.createdAt) ...[
            const SizedBox(height: 8),
            _TimeRow(
              icon: Icons.update_rounded,
              label: 'Updated',
              time: request.updatedAt!,
            ),
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
 
  const _TimeRow({
    required this.icon,
    required this.label,
    required this.time,
  });
 
  @override
  Widget build(BuildContext context) {
    final formatted =
        '${time.day}/${time.month}/${time.year}  ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
 
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.labelSmall,
        ),
        Text(
          formatted,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}