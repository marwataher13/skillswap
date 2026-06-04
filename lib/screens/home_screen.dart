import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/skill_card_data.dart';
import 'package:skillswap/models/category_model.dart';
import 'package:skillswap/models/search_result_model.dart';
import 'package:skillswap/providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/category_list.dart';
import '../widgets/skill_card.dart';
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

  // ── Data state ─────────────────────────────────────────────────────────────
  List<SkillCardData> _defaultSkills = [];
  List<CategoryModel> _categories = [];
  List<SearchResultModel> _searchResults = [];

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _isLoadingSkills = true;
  bool _isLoadingCategories = true;
  bool _isSearching = false;
  bool _isInSearchMode = false;
  String? _skillsError;
  String? _categoriesError;
  String? _searchError;

  // Selected category index (0 = "All")
  int _selectedCategoryIndex = 0;

  // Debounce timer to avoid firing a request on every keystroke
  Timer? _debounce;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

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

  // ── Data loaders ───────────────────────────────────────────────────────────

  Future<void> _loadInitialData() async {
    await Future.wait([_loadSkills(), _loadCategories()]);
  }

  Future<void> _loadSkills() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSkills = true;
      _skillsError = null;
    });

    try {
      final skills = await _skillService.fetchSkills();
      if (mounted) {
        setState(() {
          _defaultSkills = skills;
          _isLoadingSkills = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _skillsError = e.toString();
          _isLoadingSkills = false;
        });
      }
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
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoriesError = e.toString();
          _isLoadingCategories = false;
        });
      }
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _isInSearchMode = false;
        _searchResults = [];
        _searchError = null;
        _selectedCategoryIndex = 0;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _performSearch(
        query: value.trim(),
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
      final results = await _skillService.searchSkills(
        query: query,
        categoryId: categoryId,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  void _onCategorySelected(int index) {
    setState(() => _selectedCategoryIndex = index);

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _performSearch(
        query: query,
        categoryId: index == 0 ? null : _categories[index - 1].id,
      );
    }
  }

  // ── Pull-to-refresh ────────────────────────────────────────────────────────

  Future<void> _onRefresh() async {
    if (_isInSearchMode) {
      await _performSearch(
        query: _searchController.text.trim(),
        categoryId: _selectedCategoryIndex == 0
            ? null
            : _categories[_selectedCategoryIndex - 1].id,
      );
    } else {
      await _loadInitialData();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<String> get _categoryLabels => [
        'All',
        ..._categories.map((c) => c.name),
      ];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.primaryDark,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // ── Search Bar ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: HomeSearchBar(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Category List ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _buildCategorySection(),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Time Slots (hidden during search) ───────────────
                      if (!_isInSearchMode) ...[
                        const TimeSlotSection(),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // ── Skill section label ─────────────────────────────
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

                      // ── Results ─────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _isInSearchMode
                            ? _buildSearchResults()
                            : _buildDefaultSkills(),
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

  // ── Category section ───────────────────────────────────────────────────────

  Widget _buildCategorySection() {
    if (_isLoadingCategories) {
      return SizedBox(
        height: 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ShimmerChip(),
          ),
        ),
      );
    }

    if (_categoriesError != null) {
      return Text(
        'Could not load categories.',
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
      );
    }

    return CategoryList(
      categories: _categoryLabels,
      initialSelectedIndex: _selectedCategoryIndex,
      onCategorySelected: _onCategorySelected,
    );
  }

  // ── Default (non-search) skill cards ──────────────────────────────────────

  Widget _buildDefaultSkills() {
    if (_isLoadingSkills) return _buildLoadingList();

    if (_skillsError != null) {
      return _buildErrorState(
        message: 'Failed to load skills.',
        onRetry: _loadSkills,
      );
    }

    if (_defaultSkills.isEmpty) {
      return _buildEmptyState('No skills found.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _defaultSkills.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final skill = _defaultSkills[index];
        return SkillCard(
          category: skill.category,
          name: skill.name,
          type: skill.type,
        );
      },
    );
  }

  // ── Search results ─────────────────────────────────────────────────────────

  Widget _buildSearchResults() {
    if (_isSearching) return _buildLoadingList();

    if (_searchError != null) {
      return _buildErrorState(
        message: 'Search failed. Please try again.',
        onRetry: () => _performSearch(
          query: _searchController.text.trim(),
          categoryId: _selectedCategoryIndex == 0
              ? null
              : _categories[_selectedCategoryIndex - 1].id,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        'No results found for "${_searchController.text}".',
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
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => cards[i],
    );
  }

  // ── Shared state widgets ───────────────────────────────────────────────────

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

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.searchX, size: 48, color: AppColors.textHint),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.wifiOff, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
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

  // ── AppBar (v1 dynamic avatar merged into v2 layout) ──────────────────────

  Widget _buildAppBar() {
    final profile = context.watch<ProfileProvider>().profile;

    final Widget avatarWidget;
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      avatarWidget = CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(
          profile.avatarUrl!,
          headers: const {'ngrok-skip-browser-warning': 'true'},
        ),
      );
    } else {
      final parts = profile.name.trim().split(' ');
      final initials = parts.length >= 2
          ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
          : profile.name.isNotEmpty
              ? profile.name[0].toUpperCase()
              : '?';

      avatarWidget = CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary,
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

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
              color: AppColors.primaryDark,
            ),
          ),
          const Icon(LucideIcons.bell, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search result card
// ─────────────────────────────────────────────────────────────────────────────

class _SearchSkillCard extends StatelessWidget {
  final SearchResultModel result;
  final SearchSkillModel skill;

  const _SearchSkillCard({required this.result, required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.border,
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
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
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
                        const Icon(
                          LucideIcons.star,
                          size: 12,
                          color: AppColors.caramelRoast,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${result.averageRating.toStringAsFixed(1)} · ${result.name}',
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        minimumSize: const Size(100, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
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

  Widget _placeholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: const Icon(LucideIcons.user, size: 48, color: AppColors.textHint),
    );
  }
}

// ─── Level badge ──────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Text(
        level,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.mochaBean,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Shimmer placeholders ─────────────────────────────────────────────────────

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
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
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
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 90,
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),
    );
  }
}