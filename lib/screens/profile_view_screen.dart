import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/profile_models.dart';
import 'package:skillswap/models/review_model.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:skillswap/services/profile_service.dart';
import 'package:skillswap/widgets/portfolio_section.dart';
import 'package:skillswap/widgets/add_review_bottom_sheet.dart';
import '../theme/app_theme.dart';

/// Read-only static view of a user's profile card, portfolio, skills, and reviews.
/// If route arguments specify a `userId` other than the logged-in user, the screen
/// dynamically loads their details from the backend.
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
  
  bool _isInitialized = false;
  int? _resolvedUserId;
  int? _resolvedSwapRequestId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)!.settings.arguments;
      int? userId;
      int? swapRequestId;
      if (args is int) {
        userId = args;
      } else if (args is Map<String, dynamic>) {
        if (args.containsKey('userId')) {
          userId = int.tryParse(args['userId'].toString());
        }
        if (args.containsKey('swapRequestId')) {
          swapRequestId = int.tryParse(args['swapRequestId'].toString());
        }
      }
      
      _resolvedUserId = userId;
      _resolvedSwapRequestId = swapRequestId;
      
      final currentProfile = context.read<ProfileProvider>().profile;
      
      // If userId matches a different user, trigger loading
      if (userId != null && userId != currentProfile.id && userId != 0) {
        _loadOtherUserProfile(userId);
      }
      
      _isInitialized = true;
    }
  }

  Future<void> _loadOtherUserProfile(int userId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingOtherUser = true;
      _loadingError = null;
    });
    try {
      final data = await _profileService.fetchUserProfile(userId);
      
      final rawFiles = data['portfolio_files'] ?? data['portfolio'] ?? [];
      List<PortfolioItem> portfolio = [];
      if (rawFiles is List) {
        portfolio = rawFiles.map((e) => PortfolioItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      
      if (mounted) {
        setState(() {
          _otherUserData = data;
          _otherUserPortfolio = portfolio;
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
    final currentProfile = context.watch<ProfileProvider>();
    final me = currentProfile.profile;
    
    final bool isMe = _resolvedUserId == null || 
                     _resolvedUserId == me.id || 
                     _resolvedUserId == 0;

    if (_isLoadingOtherUser) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_loadingError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 40),
                const SizedBox(height: AppSpacing.md),
                Text('Failed to load profile', style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(_loadingError!, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => _loadOtherUserProfile(_resolvedUserId!),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Resolve name, avatar, bio, and stats from local Provider or dynamic fetched data
    final String name = isMe ? me.name : (_otherUserData?['name'] ?? 'No Name');
    final String? avatarUrl = isMe ? me.avatarUrl : _otherUserData?['profile_picture'];
    final String bio = isMe ? me.bio : (_otherUserData?['bio'] ?? '');
    
    final double rating = isMe 
        ? 0.0 
        : double.tryParse(_otherUserData?['average_rating']?.toString() ?? '0') ?? 0.0;
    final int trust = isMe 
        ? 0 
        : int.tryParse(_otherUserData?['trust_score']?.toString() ?? '0') ?? 0;
    final int swaps = isMe 
        ? 0 
        : int.tryParse(_otherUserData?['total_swaps']?.toString() ?? '0') ?? 0;

    final teachSkills = isMe ? [] : (_otherUserData?['teach_skills'] as List<dynamic>? ?? []);
    final learnSkills = isMe ? [] : (_otherUserData?['learn_skills'] as List<dynamic>? ?? []);
    final reviewsList = isMe ? [] : (_otherUserData?['reviews'] as List<dynamic>? ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isMe ? 'My Profile' : '$name\'s Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: isMe && currentProfile.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // ── Avatar ──
                  _buildAvatar(name, avatarUrl),
                  const SizedBox(height: 16),

                  // ── Full Name ──
                  Text(
                    name.isNotEmpty ? name : 'No Name Provided',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  // ── Stats Bar (Other User only) ──
                  if (!isMe) ...[
                    const SizedBox(height: 8),
                    _buildStatsBar(
                      averageRating: rating,
                      trustScore: trust,
                      totalSwaps: swaps,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Bio Details Card ──
                  _buildBioCard(bio),
                  const SizedBox(height: 28),

                  // ── Skills Section (Other User only) ──
                  if (!isMe && (teachSkills.isNotEmpty || learnSkills.isNotEmpty)) ...[
                    _buildSkillsSection(teachSkills, learnSkills),
                    const SizedBox(height: 12),
                  ],

                  // ── Portfolio Header ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _sectionLabel('PORTFOLIO'),
                  ),
                  const SizedBox(height: 12),

                  // ── Portfolio Grid ──
                  PortfolioSection(
                    isEditable: false,
                    items: isMe ? null : _otherUserPortfolio,
                  ),
                  const SizedBox(height: 36),

                  // ── Reviews Section (Other User only) ──
                  if (!isMe) ...[
                    _buildReviewsSection(reviewsList),
                    const SizedBox(height: 40),
                  ],

                  const SizedBox(height: 60),
                ],
              ),
            ),
      floatingActionButton: isMe
          ? null
          : FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddReviewBottomSheet(
                    userId: _resolvedUserId ?? 1,
                    swapRequestId: _resolvedSwapRequestId ?? 1,
                    onSaved: () {
                      _loadOtherUserProfile(_resolvedUserId ?? 1);
                    },
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: 'Add Review',
              child: const Icon(Icons.rate_review_rounded),
            ),
    );
  }

  Widget _buildAvatar(String name, String? avatarUrl) {
    Widget imageWidget;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      imageWidget = ClipOval(
        child: Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          headers: const {
            'ngrok-skip-browser-warning': 'true',
          },
          errorBuilder: (context, error, stackTrace) => _initials(name),
        ),
      );
    } else {
      imageWidget = _initials(name);
    }

    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: imageWidget,
      ),
    );
  }

  Widget _initials(String name) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBioCard(String bio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.text,
              size: 18,
              color: AppColors.primary,
            ),
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
                    color: AppColors.textHint,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bio.isNotEmpty ? bio : 'No Bio Provided',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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
    required int trustScore,
    required int totalSwaps,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: AppShadows.subtle,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 6),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: AppShadows.subtle,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, color: AppColors.success, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Trust: $trustScore',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: AppShadows.subtle,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.refreshCw, color: AppColors.primary, size: 12),
                const SizedBox(width: 6),
                Text(
                  '$totalSwaps swaps',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(List<dynamic> teachSkills, List<dynamic> learnSkills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (teachSkills.isNotEmpty) ...[
          _sectionLabel('TEACHING SKILLS'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: teachSkills.map((s) {
              final skill = s is Map ? s : {};
              final name = skill['name']?.toString() ?? 'Skill';
              final level = skill['level']?.toString() ?? 'beginner';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F0D9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: const Color(0xFFC5E0B4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.graduationCap, size: 13, color: Color(0xFF385723)),
                    const SizedBox(width: 6),
                    Text(
                      '$name (${level.toUpperCase()})',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF385723),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (learnSkills.isNotEmpty) ...[
          _sectionLabel('LEARNING SKILLS'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: learnSkills.map((s) {
              final skill = s is Map ? s : {};
              final name = skill['name']?.toString() ?? 'Skill';
              final level = skill['level']?.toString() ?? 'beginner';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2CC),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: const Color(0xFFFFD966)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.bookOpen, size: 13, color: Color(0xFF7F6000)),
                    const SizedBox(width: 6),
                    Text(
                      '$name (${level.toUpperCase()})',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7F6000),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildReviewsSection(List<dynamic> rawReviews) {
    final reviews = rawReviews.map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('REVIEWS (${reviews.length})'),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppShadows.card,
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.messageSquare, size: 28, color: AppColors.textHint),
                  const SizedBox(height: 10),
                  Text(
                    'No reviews yet',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
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
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryLight,
                          foregroundImage: review.reviewerImage.isNotEmpty
                              ? NetworkImage(review.reviewerImage)
                              : null,
                          child: Text(
                            review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
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
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    LucideIcons.star,
                                    size: 11,
                                    color: starIndex < review.rating ? Colors.amber : Colors.grey.shade300,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(review.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      review.comment,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 0.8,
      ),
    );
  }
}
