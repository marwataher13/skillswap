import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/top_user_model.dart';
import 'package:skillswap/models/search_result_model.dart';
import 'package:skillswap/services/skill_service.dart';
import 'package:skillswap/services/chat_service.dart';
import 'package:skillswap/screens/chat_messages_screen.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:skillswap/theme/app_theme.dart';

class TopTeachersScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const TopTeachersScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<TopTeachersScreen> createState() => _TopTeachersScreenState();
}

class _TopTeachersScreenState extends State<TopTeachersScreen> {
  final SkillService _skillService = SkillService();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();

  List<TopUserModel> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isInitiatingChat = false;
  int? _chattingUserId;

  @override
  void initState() {
    super.initState();
    _loadTopUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _currentPage < _lastPage) {
        _loadMore();
      }
    }
  }

  Future<void> _loadTopUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _skillService.fetchTopUsers(widget.categoryId, page: 1);
      if (mounted) {
        setState(() {
          _users = response.results;
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _skillService.fetchTopUsers(widget.categoryId, page: nextPage);
      if (mounted) {
        setState(() {
          _users.addAll(response.results);
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more teachers: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
        );
      }
    }
  }

  Future<void> _contactTeacher(TopUserModel teacher) async {
    setState(() {
      _isInitiatingChat = true;
      _chattingUserId = teacher.userId;
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final conversation = await _chatService.getOrCreateConversation(teacher.userId);
      if (!mounted) return;
      setState(() {
        _isInitiatingChat = false;
        _chattingUserId = null;
      });

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatMessagesScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitiatingChat = false;
        _chattingUserId = null;
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _viewDetails(TopUserModel user) {
    final searchSkill = SearchSkillModel(
      id: user.skill?.id ?? 0,
      name: user.skill?.name ?? '',
      description: user.skill?.description ?? '',
      level: user.skill?.level ?? 'beginner',
      type: 'teach',
      category: widget.categoryName,
    );

    final searchResult = SearchResultModel(
      userId: user.userId,
      name: user.name,
      profilePicture: user.profilePicture,
      trustScore: user.trustScore,
      averageRating: user.averageRating,
      skills: [searchSkill],
    );

    Navigator.pushNamed(
      context,
      '/skill-details',
      arguments: {
        'result': searchResult,
        'skill': searchSkill,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTopUsers,
          color: AppColors.primaryDark,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.alertTriangle,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load teachers',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _loadTopUsers,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(120, 45),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.users,
                  color: AppColors.textHint,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No Teachers Found',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Be the first to list a teaching skill in this category!',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentProfile = context.watch<ProfileProvider>().profile;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _users.length + 1,
      itemBuilder: (context, index) {
        if (index == _users.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : const SizedBox.shrink();
        }

        final user = _users[index];
        final isMe = currentProfile.name.toLowerCase().trim() == user.name.toLowerCase().trim();
        final skillName = user.skill?.name ?? 'No skill listed';
        final skillLevel = user.skill?.level ?? 'beginner';
        final skillDesc = user.skill?.description ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: AppShadows.subtle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Avatar + Name + Trust score)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryLight,
                      foregroundImage: user.profilePicture.isNotEmpty
                          ? NetworkImage(user.profilePicture)
                          : null,
                      onForegroundImageError: user.profilePicture.isNotEmpty
                          ? (exception, stackTrace) {
                              debugPrint('Failed to load profile image: $exception');
                            }
                          : null,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMe)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    'You',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(LucideIcons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                user.averageRating.toStringAsFixed(1),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Icon(LucideIcons.refreshCw, color: AppColors.textSecondary, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${user.totalSwaps} swaps',
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Skill Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              skillName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Text(
                              skillLevel.toUpperCase(),
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 10,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (skillDesc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          skillDesc,
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Footer (Trust Score + Buttons)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Trust Score Badge
                    Row(
                      children: [
                        const Icon(LucideIcons.shieldCheck, color: AppColors.success, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Trust Score: ${user.trustScore}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Actions
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _viewDetails(user),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'Details',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isMe)
                          ElevatedButton(
                            onPressed: _isInitiatingChat ? null : () => _contactTeacher(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: _isInitiatingChat && _chattingUserId == user.userId
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.messageCircle, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Chat',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
