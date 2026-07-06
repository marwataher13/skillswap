import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/category_model.dart';
import 'package:skillswap/models/search_result_model.dart';
import 'package:skillswap/models/recommendation_model.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:skillswap/providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/category_list.dart';
import '../widgets/ai_assistant_fab.dart';
// ignore: unused_import
import '../widgets/time_slot_section.dart';
import '../services/skill_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _skillService = SkillService();
  final _searchController = TextEditingController();

  List<SearchResultModel> _defaultSkills = [];
  List<CategoryModel> _categories = [];
  List<SearchResultModel> _searchResults = [];
  List<RecommendationModel> _recommendations = [];

  bool _isLoadingSkills = true;
  bool _isLoadingCategories = true;
  bool _isSearching = false;
  bool _isInSearchMode = false;
  bool _isLoadingRecommendations = true;

  String? _skillsError;
  String? _categoriesError;
  String? _searchError;
  String? _recommendationsError;

  int _selectedCategoryIndex = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _loadRecommendations();
    await _loadCategories();
    if (_categories.isNotEmpty) {
      await _loadFeaturedFeed();
    }
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRecommendations = true;
      _recommendationsError = null;
    });
    try {
      final list = await _skillService.fetchRecommendations();
      if (mounted) {
        setState(() {
          _recommendations = list;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recommendationsError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _loadFeaturedFeed() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSkills = true;
      _skillsError = null;
    });
    try {
      final List<SearchResultModel> feed = [];
      for (int i = 0; i < _categories.length; i++) {
        try {
          final topUsersResponse = await _skillService.fetchTopUsers(
            _categories[i].id,
            page: 1,
          );
          for (final tu in topUsersResponse.results) {
            feed.add(
              SearchResultModel(
                userId: tu.userId,
                name: tu.name,
                profilePicture: tu.profilePicture,
                trustScore: tu.trustScore,
                averageRating: tu.averageRating,
                skills: tu.skill != null
                    ? [
                        SearchSkillModel(
                          id: tu.skill!.id,
                          name: tu.skill!.name,
                          description: tu.skill!.description,
                          level: tu.skill!.level,
                          type: 'teach',
                          category: _categories[i].name,
                        ),
                      ]
                    : [],
              ),
            );
          }
        } catch (e, s) {
          debugPrint('Failed loading category feed index $i: $e\n$s');
        }
      }
      feed.shuffle();
      if (mounted)
        setState(() {
          _defaultSkills = feed;
          _isLoadingSkills = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _skillsError = 'Failed to load feed: $e';
          _isLoadingSkills = false;
        });
    }
  }

  Future<void> _loadCategoryFeed(int categoryId, String categoryName) async {
    if (!mounted) return;
    setState(() {
      _isLoadingSkills = true;
      _skillsError = null;
    });
    try {
      final topUsersResponse = await _skillService.fetchTopUsers(
        categoryId,
        page: 1,
      );
      final List<SearchResultModel> feed = [];
      for (final tu in topUsersResponse.results) {
        feed.add(
          SearchResultModel(
            userId: tu.userId,
            name: tu.name,
            profilePicture: tu.profilePicture,
            trustScore: tu.trustScore,
            averageRating: tu.averageRating,
            skills: tu.skill != null
                ? [
                    SearchSkillModel(
                      id: tu.skill!.id,
                      name: tu.skill!.name,
                      description: tu.skill!.description,
                      level: tu.skill!.level,
                      type: 'teach',
                      category: categoryName,
                    ),
                  ]
                : [],
          ),
        );
      }
      if (mounted)
        setState(() {
          _defaultSkills = feed;
          _isLoadingSkills = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _skillsError = 'Failed to load category feed: $e';
          _isLoadingSkills = false;
        });
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });
    try {
      final categories = await _skillService.fetchCategories();
      if (mounted)
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _categoriesError = e.toString();
          _isLoadingCategories = false;
        });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _isInSearchMode = false;
        _searchResults = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _performSearch(
        query: query,
        categoryId: _selectedCategoryIndex == 0
            ? null
            : _categories[_selectedCategoryIndex - 1].id,
      );
    });
  }

  Future<void> _performSearch({required String query, int? categoryId}) async {
    if (!mounted) return;
    setState(() {
      _isInSearchMode = true;
      _isSearching = true;
      _searchError = null;
    });
    try {
      final response = await _skillService.searchSkills(
        query: query,
        categoryId: categoryId,
      );
      if (mounted)
        setState(() {
          _searchResults = response.results;
          _isSearching = false;
        });
    } catch (e, stack) {
      debugPrint('Search Exception: $e\n$stack');
      if (mounted)
        setState(() {
          _searchError = 'Search failed: $e';
          _isSearching = false;
        });
    }
  }

  void _onCategorySelected(int index) {
    setState(() => _selectedCategoryIndex = index);
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _isInSearchMode = false;
        _searchResults = [];
        _searchError = null;
      });
      if (index == 0) {
        _loadFeaturedFeed();
      } else {
        _loadCategoryFeed(
          _categories[index - 1].id,
          _categories[index - 1].name,
        );
      }
    } else {
      _performSearch(
        query: query,
        categoryId: index == 0 ? null : _categories[index - 1].id,
      );
    }
  }

  Future<void> _onRefresh() async {
    final query = _searchController.text.trim();
    if (_isInSearchMode && query.length >= 2) {
      await _performSearch(
        query: query,
        categoryId: _selectedCategoryIndex == 0
            ? null
            : _categories[_selectedCategoryIndex - 1].id,
      );
    } else {
      await Future.wait([_loadRecommendations(), _loadCategories()]);
      if (_categories.isNotEmpty) {
        await _loadFeaturedFeed();
      }
    }
  }

  List<String> get _categoryLabels => [
    'All',
    ..._categories.map((c) => c.name),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: const AiAssistantFab(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(c),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: c.primaryDark,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: HomeSearchBar(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onFilterPressed: () =>
                              Navigator.pushNamed(context, '/search'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Categories',
                              style: AppTextStyles.titleMedium,
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/categories'),
                              child: Text(
                                'See All',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: c.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _buildCategorySection(c),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (!_isInSearchMode && _selectedCategoryIndex == 0) ...[
                        _buildRecommendationsSection(c),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (!_isInSearchMode)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            12,
                          ),
                          child: Text(
                            'Browse Skills',
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _isInSearchMode
                            ? _buildSearchResults(c)
                            : _buildDefaultSkills(c),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(AppColorsExtension c) {
    if (_isLoadingCategories) {
      return SizedBox(
        height: 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (_, _) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ShimmerChip(),
          ),
        ),
      );
    }
    if (_categoriesError != null) {
      return Text(
        'Could not load categories.',
        style: AppTextStyles.labelSmall.copyWith(color: c.error),
      );
    }
    return CategoryList(
      categories: _categoryLabels,
      initialSelectedIndex: _selectedCategoryIndex,
      onCategorySelected: _onCategorySelected,
    );
  }

  Widget _buildDefaultSkills(AppColorsExtension c) {
    if (_isLoadingSkills) return _buildLoadingList();
    if (_skillsError != null) {
      return _buildErrorState(
        message: _skillsError!,
        onRetry: () {
          if (_selectedCategoryIndex == 0) {
            _loadFeaturedFeed();
          } else {
            _loadCategoryFeed(
              _categories[_selectedCategoryIndex - 1].id,
              _categories[_selectedCategoryIndex - 1].name,
            );
          }
        },
        c: c,
      );
    }
    if (_defaultSkills.isEmpty)
      return _buildEmptyState('No skills found in this feed.', c);
    final cards = <Widget>[];
    for (final user in _defaultSkills) {
      for (final skill in user.skills) {
        cards.add(_SearchSkillCard(result: user, skill: skill));
      }
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => cards[i],
    );
  }

  Widget _buildSearchResults(AppColorsExtension c) {
    if (_isSearching) return _buildLoadingList();
    if (_searchError != null) {
      return _buildErrorState(
        message: _searchError!,
        onRetry: () => _performSearch(
          query: _searchController.text.trim(),
          categoryId: _selectedCategoryIndex == 0
              ? null
              : _categories[_selectedCategoryIndex - 1].id,
        ),
        c: c,
      );
    }
    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        'No results found for "${_searchController.text}".',
        c,
      );
    }
    final cards = <Widget>[];
    for (final result in _searchResults) {
      for (final skill in result.skills) {
        cards.add(_SearchSkillCard(result: result, skill: skill));
      }
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => cards[i],
    );
  }

  Widget _buildRecommendationsSection(AppColorsExtension c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(LucideIcons.sparkles, color: c.primary, size: 20),
              const SizedBox(width: 8),
              Text('Recommended For You', style: AppTextStyles.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildRecommendationsContent(c),
        ),
      ],
    );
  }

  Widget _buildRecommendationsContent(AppColorsExtension c) {
    if (_isLoadingRecommendations) {
      return _buildLoadingList();
    }

    if (_recommendationsError != null) {
      final err = _recommendationsError!;
      final isSkillWarning =
          err.contains('Please add your skills') ||
          err.contains('Please add at least one skill');

      if (isSkillWarning) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: AppShadows.card,
            border: Border.all(color: c.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(LucideIcons.sparkles, size: 36, color: c.primary),
              const SizedBox(height: 12),
              Text(
                err,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  'Add Skills Now',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return _buildErrorState(
        message: err,
        onRetry: _loadRecommendations,
        c: c,
      );
    }

    if (_recommendations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppShadows.card,
        ),
        child: Center(
          child: Text(
            'No recommendations found yet.',
            style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendations.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rec = _recommendations[index];
        return _RecommendationCard(rec: rec);
      },
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _ShimmerCard(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, AppColorsExtension c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.searchX, size: 48, color: c.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
    required AppColorsExtension c,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.wifiOff, size: 48, color: c.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTextStyles.labelMedium.copyWith(color: c.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppColorsExtension c) {
    final profile = context.watch<ProfileProvider>().profile;
    final parts = profile.name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : '?';

    final Widget avatarWidget = CircleAvatar(
      radius: 20,
      backgroundColor: c.primary,
      foregroundImage:
          (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
          ? NetworkImage(
              profile.avatarUrl!,
              headers: const {'ngrok-skip-browser-warning': 'true'},
            )
          : null,
      onForegroundImageError:
          (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
          ? (exception, stackTrace) {
              debugPrint('Failed to load profile image: $exception');
            }
          : null,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: avatarWidget,
          ),
          Text(
            'SkillSwap',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: c.primaryDark,
            ),
          ),
          _buildNotificationBell(context, c),
        ],
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context, AppColorsExtension c) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/notifications'),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(LucideIcons.bell, color: c.textPrimary),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: c.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchSkillCard extends StatelessWidget {
  final SearchResultModel result;
  final SearchSkillModel skill;

  const _SearchSkillCard({required this.result, required this.skill});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.border,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
            child: result.profilePicture.isNotEmpty
                ? Image.network(
                    result.profilePicture,
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(c),
                  )
                : _placeholder(c),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(skill.category, style: AppTextStyles.labelSmall),
                    if (skill.level.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _LevelBadge(level: skill.level),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  skill.name,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                if (skill.description.isNotEmpty)
                  Text(
                    skill.description,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.star, size: 12, color: c.caramelRoast),
                        const SizedBox(width: 4),
                        Text(
                          '${result.averageRating.toStringAsFixed(1)} · ${result.name}',
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/skill-details',
                          arguments: {'result': result, 'skill': skill},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primaryLight,
                        minimumSize: const Size(100, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(fontSize: 12, color: c.textPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(AppColorsExtension c) {
    return Container(
      height: 180,
      width: double.infinity,
      color: c.surfaceVariant,
      child: Icon(LucideIcons.user, size: 48, color: c.textHint),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: c.primary.withValues(alpha: 0.4)),
      ),
      child: Text(
        level,
        style: AppTextStyles.labelSmall.copyWith(
          color: c.mochaBean,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}

class _ShimmerChip extends StatefulWidget {
  @override
  State<_ShimmerChip> createState() => _ShimmerChipState();
}

class _ShimmerChipState extends State<_ShimmerChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 90,
        height: 45,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RecommendationModel rec;
  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
        border: Border.all(color: c.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: c.primary,
                foregroundImage: rec.profilePicture.isNotEmpty
                    ? NetworkImage(
                        rec.profilePicture,
                        headers: const {'ngrok-skip-browser-warning': 'true'},
                      )
                    : null,
                child: Text(
                  rec.name.isNotEmpty ? rec.name[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.name,
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                    ),
                    if (rec.username.isNotEmpty)
                      Text(
                        '@${rec.username}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: c.textHint,
                        ),
                      ),
                  ],
                ),
              ),
              if (rec.matchScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.gradientStart, c.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${rec.matchScore!.toStringAsFixed(0)}% Match',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (rec.skillsTeach.isNotEmpty) ...[
            _buildSkillRow(
              title: 'Teaches',
              skills: rec.skillsTeach,
              chipColor: c.primary.withValues(alpha: 0.08),
              textColor: c.primaryDark,
              c: c,
            ),
            const SizedBox(height: 8),
          ],
          if (rec.skillsLearn.isNotEmpty) ...[
            _buildSkillRow(
              title: 'Wants to Learn',
              skills: rec.skillsLearn,
              chipColor: c.surfaceVariant.withValues(alpha: 0.5),
              textColor: c.textSecondary,
              c: c,
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/profile',
                  arguments: {'userId': rec.userId},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primaryLight,
                foregroundColor: c.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                'View Profile',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow({
    required String title,
    required List<String> skills,
    required Color chipColor,
    required Color textColor,
    required AppColorsExtension c,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            color: c.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: skills.map((s) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: chipColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                s,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
