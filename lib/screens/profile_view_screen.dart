import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/profile_models.dart';
import 'package:skillswap/models/review_model.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:skillswap/services/profile_service.dart';
import 'package:skillswap/services/time_slot_service.dart';
import 'package:skillswap/widgets/portfolio_section.dart';
import 'package:skillswap/widgets/add_review_bottom_sheet.dart';
import 'package:skillswap/providers/swap_request_provider.dart';
import 'package:skillswap/providers/review_provider.dart';
import 'package:skillswap/models/time_slot_model.dart';
import 'package:skillswap/widgets/time_slot_section.dart';
import '../theme/app_theme.dart';

/// Read-only view of a user's profile, portfolio, skills, and reviews.
/// Accepts a `userId` argument (int or `{'userId': int}`).
class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoadingOtherUser = false;
  String? _loadingError;

  Map<String, dynamic>? _otherUserData;
  List<PortfolioItem> _otherUserPortfolio = [];
  List<TimeSlotModel> _otherUserTimeSlots = [];

  bool _isInitialized = false;
  int? _resolvedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final args = ModalRoute.of(context)!.settings.arguments;
    int? userId;
    if (args is int) {
      userId = args;
    } else if (args is Map<String, dynamic> && args.containsKey('userId')) {
      userId = int.tryParse(args['userId'].toString());
    }

    final currentProfile = context.read<ProfileProvider>().profile;
    final targetId = (userId == null || userId == 0) ? currentProfile.id : userId;

    _resolvedUserId = targetId;
    _loadOtherUserProfile(targetId);
    _isInitialized = true;
  }

  Future<void> _loadOtherUserProfile(int userId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingOtherUser = true;
      _loadingError = null;
    });
    try {
      final results = await Future.wait([
        _profileService.fetchUserProfile(userId),
        TimeSlotService().getUserTimeSlots(userId),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final slots = results[1] as List<TimeSlotModel>;

      final rawFiles = data['portfolio_files'] ?? data['portfolio'] ?? [];
      List<PortfolioItem> portfolio = [];
      if (rawFiles is List) {
        portfolio = rawFiles
            .map((e) => PortfolioItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (mounted) {
        setState(() {
          _otherUserData = data;
          _otherUserPortfolio = portfolio;
          _otherUserTimeSlots = slots;
          _isLoadingOtherUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.toString().replaceAll('Exception: ', '');
          _isLoadingOtherUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final currentProfile = context.watch<ProfileProvider>();
    final me = currentProfile.profile;

    final bool isMe = _resolvedUserId == null ||
        _resolvedUserId == me.id ||
        _resolvedUserId == 0;

    final acceptedRequest = _resolvedUserId != null
        ? context.watch<SwapRequestProvider>().getAcceptedRequestWithUser(_resolvedUserId!)
        : null;

    if (_isLoadingOtherUser) {
      return _LoadingScaffold(onBack: () => Navigator.pop(context));
    }

    if (_loadingError != null) {
      return _ErrorScaffold(
        error: _loadingError!,
        onBack: () => Navigator.pop(context),
        onRetry: () => _loadOtherUserProfile(_resolvedUserId!),
      );
    }

    final String name = isMe ? me.name : (_otherUserData?['name'] ?? 'No Name');
    final String username = isMe ? me.username : (_otherUserData?['username'] ?? '');
    final String? avatarUrl = isMe ? me.avatarUrl : _otherUserData?['profile_picture'];
    final String bio = isMe ? me.bio : (_otherUserData?['bio'] ?? '');

    final swapsProvider = context.watch<SwapRequestProvider>();
    final int localAcceptedCount = swapsProvider.sent.where((r) => r.status == 'accepted').length +
        swapsProvider.received.where((r) => r.status == 'accepted').length;

    final int otherUserLocalAcceptedCount = swapsProvider.sent.where((r) => r.receiverId == _resolvedUserId && r.status == 'accepted').length +
        swapsProvider.received.where((r) => r.senderId == _resolvedUserId && r.status == 'accepted').length;

    final rating = isMe ? me.averageRating : (double.tryParse((_otherUserData?['average_rating'] ?? me.averageRating).toString()) ?? 0.0);
    final trust = isMe ? me.trustScore : (double.tryParse((_otherUserData?['trust_score'] ?? me.trustScore).toString()) ?? 0.0);
    final baseOtherSwaps = int.tryParse((_otherUserData?['total_swaps'] ?? me.totalSwaps).toString()) ?? 0;
    final swaps = isMe ? localAcceptedCount : (baseOtherSwaps > 0 ? baseOtherSwaps : otherUserLocalAcceptedCount);

    final teachSkills = _otherUserData?['teach_skills'] as List<dynamic>? ?? [];
    final learnSkills = _otherUserData?['learn_skills'] as List<dynamic>? ?? [];
    final reviewsList = _otherUserData?['reviews'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isMe ? 'My Profile' : "$name's Profile",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
      body: isMe && currentProfile.isLoading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildAvatar(name, avatarUrl, c),
                  const SizedBox(height: 16),
                  Text(
                    name.isNotEmpty ? name : 'No Name Provided',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildStatsBar(
                    averageRating: rating,
                    trustScore: trust,
                    totalSwaps: swaps,
                    c: c,
                  ),
                  const SizedBox(height: 24),
                  _buildBioCard(bio, c),
                  const SizedBox(height: 28),
                  if (teachSkills.isNotEmpty || learnSkills.isNotEmpty) ...[
                    _buildSkillsSection(teachSkills, learnSkills, c),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _sectionLabel('AVAILABILITY', c),
                  ),
                  const SizedBox(height: 12),
                  TimeSlotSection(
                    userId: _resolvedUserId,
                    isReadOnly: !isMe,
                    initialSlots: isMe ? null : _otherUserTimeSlots,
                  ),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _sectionLabel('PORTFOLIO', c),
                  ),
                  const SizedBox(height: 12),
                  PortfolioSection(
                    isEditable: false,
                    items: isMe ? null : _otherUserPortfolio,
                  ),
                  const SizedBox(height: 36),
                  _buildReviewsSection(reviewsList, me.id, c),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      floatingActionButton: isMe || acceptedRequest == null
          ? null
          : FloatingActionButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddReviewBottomSheet(
                  userId: _resolvedUserId!,
                  swapRequestId: acceptedRequest.id,
                  requestedSkillName: acceptedRequest.requestedSkill,
                  onSaved: () => _loadOtherUserProfile(_resolvedUserId!),
                ),
              ),
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
              tooltip: 'Add Review',
              child: const Icon(Icons.rate_review_rounded),
            ),
    );
  }

  Widget _buildAvatar(String name, String? avatarUrl, AppColorsExtension c) {
    final Widget imageWidget = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? ClipOval(
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              headers: const {'ngrok-skip-browser-warning': 'true'},
              errorBuilder: (_, _, _) => _Initials(name: name, size: 36),
            ),
          )
        : _Initials(name: name, size: 36);

    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [c.gradientStart, c.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: imageWidget,
      ),
    );
  }

  Widget _buildBioCard(String bio, AppColorsExtension c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.text, size: 18, color: c.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIO',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.textHint,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bio.isNotEmpty ? bio : 'No Bio Provided',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar({
    required double averageRating,
    required double trustScore,
    required int totalSwaps,
    required AppColorsExtension c,
  }) {
    final trustStr = trustScore % 1 == 0 ? trustScore.toInt().toString() : trustScore.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatChip(
            icon: LucideIcons.star,
            iconColor: Colors.amber,
            label: averageRating.toStringAsFixed(1),
            labelColor: c.textPrimary,
            surfaceColor: c.surface,
            borderColor: c.border,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: LucideIcons.shieldCheck,
            iconColor: c.success,
            label: 'Trust: $trustStr',
            labelColor: c.success,
            surfaceColor: c.surface,
            borderColor: c.border,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: LucideIcons.refreshCw,
            iconColor: c.primary,
            iconSize: 12,
            label: '$totalSwaps swaps',
            labelColor: c.textPrimary,
            surfaceColor: c.surface,
            borderColor: c.border,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(
    List<dynamic> teachSkills,
    List<dynamic> learnSkills,
    AppColorsExtension c,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (teachSkills.isNotEmpty) ...[
          _sectionLabel('TEACHING SKILLS', c),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: teachSkills.map((s) {
              final skill = s is Map ? s : <String, dynamic>{};
              return _SkillChip(
                name: skill['name']?.toString() ?? 'Skill',
                level: skill['level']?.toString() ?? 'beginner',
                isTeach: true,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (learnSkills.isNotEmpty) ...[
          _sectionLabel('LEARNING SKILLS', c),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: learnSkills.map((s) {
              final skill = s is Map ? s : <String, dynamic>{};
              return _SkillChip(
                name: skill['name']?.toString() ?? 'Skill',
                level: skill['level']?.toString() ?? 'beginner',
                isTeach: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildReviewsSection(
    List<dynamic> rawReviews,
    int currentUserId,
    AppColorsExtension c,
  ) {
    final reviews = rawReviews
        .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('REVIEWS (${reviews.length})', c),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppShadows.card,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.messageSquare, size: 28, color: c.textHint),
                  const SizedBox(height: 10),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            itemBuilder: (context, index) => _ReviewCard(
              key: ValueKey(reviews[index].id),
              review: reviews[index],
              canDelete: reviews[index].reviewerId == currentUserId,
              onDelete: _confirmDeleteReview,
              formatDate: _formatDate,
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDeleteReview(int reviewId) async {
    final c = context.appColors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text(
          'Are you sure you want to delete this review? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: c.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: c.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Deleting review...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );

    try {
      await context.read<ReviewProvider>().removeReview(reviewId);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review deleted successfully!'),
            backgroundColor: c.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        );
        _loadOtherUserProfile(_resolvedUserId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete review: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: c.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';

  Widget _sectionLabel(String text, AppColorsExtension c) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.primary,
          letterSpacing: 0.8,
        ),
      );
}

// ── Shared helper widgets ────────────────────────────────────────────────────

class _Initials extends StatelessWidget {
  final String name;
  final double size;

  const _Initials({required this.name, this.size = 24});

  String get _text {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _text,
        style: GoogleFonts.poppins(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String label;
  final Color labelColor;
  final Color surfaceColor;
  final Color borderColor;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.surfaceColor,
    required this.borderColor,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppShadows.subtle,
        border: Border.all(color: borderColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String name;
  final String level;
  final bool isTeach;

  const _SkillChip({
    required this.name,
    required this.level,
    required this.isTeach,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isTeach ? const Color(0xFFE2F0D9) : const Color(0xFFFFF2CC);
    final borderColor = isTeach ? const Color(0xFFC5E0B4) : const Color(0xFFFFD966);
    final textColor = isTeach ? const Color(0xFF385723) : const Color(0xFF7F6000);
    final icon = isTeach ? LucideIcons.graduationCap : LucideIcons.bookOpen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 6),
          Text(
            '$name (${level.toUpperCase()})',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading / Error scaffold helpers ────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  final VoidCallback onBack;
  const _LoadingScaffold({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary, size: 22),
          onPressed: onBack,
        ),
      ),
      body: Center(child: CircularProgressIndicator(color: c.primary)),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String error;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _ErrorScaffold({
    required this.error,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary, size: 22),
          onPressed: onBack,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertTriangle, color: c.error, size: 40),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load profile', style: AppTextStyles.titleMedium),
              const SizedBox(height: 4),
              Text(error, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: c.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Review card ──────────────────────────────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  final ReviewModel review;
  final bool canDelete;
  final Future<void> Function(int) onDelete;
  final String Function(DateTime) formatDate;

  const _ReviewCard({
    super.key,
    required this.review,
    required this.canDelete,
    required this.onDelete,
    required this.formatDate,
  });

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  List<String> _teachSkills = [];

  @override
  void initState() {
    super.initState();
    if (widget.review.reviewerTeachSkills.isNotEmpty) {
      _teachSkills = widget.review.reviewerTeachSkills;
    } else {
      _fetchReviewerSkills();
    }
  }

  Future<void> _fetchReviewerSkills() async {
    if (widget.review.reviewerId <= 0) return;
    try {
      final data = await ProfileService().fetchUserProfile(widget.review.reviewerId);
      final rawSkills = data['teach_skills'] as List<dynamic>? ?? [];
      final names = rawSkills
          .map((s) => s is Map ? s['name']?.toString() ?? '' : s.toString())
          .where((n) => n.isNotEmpty)
          .toList();
      if (mounted && names.isNotEmpty) {
        setState(() => _teachSkills = names);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final review = widget.review;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: c.primaryLight,
                foregroundImage: review.reviewerImage.isNotEmpty
                    ? NetworkImage(
                        review.reviewerImage,
                        headers: const {'ngrok-skip-browser-warning': 'true'},
                      )
                    : null,
                child: Text(
                  review.reviewerName.isNotEmpty
                      ? review.reviewerName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          LucideIcons.star,
                          size: 11,
                          color: i < review.rating ? Colors.amber : Colors.grey.shade300,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                widget.formatDate(review.createdAt),
                style: GoogleFonts.poppins(fontSize: 11, color: c.textHint),
              ),
              if (widget.canDelete) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => widget.onDelete(review.id),
                  child: Icon(Icons.delete_outline_rounded, color: c.error, size: 18),
                ),
              ],
            ],
          ),
          if (_teachSkills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _teachSkills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: c.primary.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.graduationCap, size: 10, color: c.primary),
                      const SizedBox(width: 4),
                      Text(
                        skill,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            review.cleanComment,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: c.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
