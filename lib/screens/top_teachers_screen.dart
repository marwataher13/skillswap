import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/top_user_model.dart';
import 'package:skillswap/models/search_result_model.dart';
import 'package:skillswap/services/skill_service.dart';
import 'package:skillswap/screens/chat_messages_screen.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:skillswap/providers/chat_provider.dart';
import 'package:skillswap/providers/swap_request_provider.dart';
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
    setState(() => _isLoadingMore = true);
    final errorColor = context.appColors.error;
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
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more teachers: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
        );
      }
    }
  }

  Future<void> _contactTeacher(TopUserModel teacher) async {
    final swapRequestProvider = context.read<SwapRequestProvider>();
    final acceptedRequest = swapRequestProvider.getAcceptedRequestWithUser(teacher.userId);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = context.appColors.error;

    if (acceptedRequest == null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Chatting is only allowed once a Swap Request has been accepted.'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
      return;
    }

    setState(() {
      _isInitiatingChat = true;
      _chattingUserId = teacher.userId;
    });
    final chatProvider = context.read<ChatProvider>();
    final navigator = Navigator.of(context);

    try {
      final conversation = await chatProvider.getOrCreateAndOpenConversation(teacher.userId, acceptedRequest.id);
      if (!mounted) return;
      setState(() {
        _isInitiatingChat = false;
        _chattingUserId = null;
      });
      navigator.push(
        MaterialPageRoute(builder: (_) => ChatMessagesScreen(conversation: conversation)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitiatingChat = false;
        _chattingUserId = null;
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
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
      arguments: {'result': searchResult, 'skill': searchSkill},
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: c.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTopUsers,
          color: c.primaryDark,
          child: _buildContent(c),
        ),
      ),
    );
  }

  Widget _buildContent(AppColorsExtension c) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
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
                Icon(LucideIcons.alertTriangle, color: c.error, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load teachers',
                  style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _loadTopUsers,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
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
                Icon(LucideIcons.users, color: c.textHint, size: 64),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No Teachers Found',
                  style: AppTextStyles.titleMedium.copyWith(color: c.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Be the first to list a teaching skill in this category!',
                  style: AppTextStyles.bodyMedium.copyWith(color: c.textHint),
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
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator(color: c.primary)),
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
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: c.border.withValues(alpha: 0.3), width: 1),
            boxShadow: AppShadows.subtle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: c.primaryLight,
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
                          color: c.textPrimary,
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
                                    color: c.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMe)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: c.primaryLight,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    'You',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: c.textPrimary,
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
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(LucideIcons.refreshCw, color: c.textSecondary, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${user.totalSwaps} swaps',
                                style: AppTextStyles.labelSmall.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: c.background.withValues(alpha: 0.5),
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
                                color: c.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.primaryLight,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Text(
                              skillLevel.toUpperCase(),
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 10,
                                color: c.textPrimary,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.shieldCheck, color: c.success, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Trust Score: ${user.trustScore % 1 == 0 ? user.trustScore.toInt().toString() : user.trustScore.toStringAsFixed(2)}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: c.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _viewDetails(user),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: c.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'Details',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: c.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isMe)
                          ElevatedButton(
                            onPressed: _isInitiatingChat ? null : () => _contactTeacher(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.primary,
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
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.messageCircle, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Chat',
                                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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
