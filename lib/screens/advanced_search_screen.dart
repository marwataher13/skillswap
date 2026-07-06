import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/category_model.dart';
import 'package:skillswap/models/search_result_model.dart';
import 'package:skillswap/services/skill_service.dart';
import 'package:skillswap/screens/chat_messages_screen.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:skillswap/providers/chat_provider.dart';
import 'package:skillswap/providers/swap_request_provider.dart';
import 'package:skillswap/theme/app_theme.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final SkillService _skillService = SkillService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<CategoryModel> _categories = [];
  List<SearchResultModel> _results = [];
  
  bool _isLoadingCategories = true;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _searchError;
  
  int? _selectedCategoryId;
  String _selectedType = 'all'; // 'all', 'teach', 'learn'
  
  int _currentPage = 1;
  int _lastPage = 1;
  Timer? _debounce;
  bool _isInitiatingChat = false;
  int? _chattingUserId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _performSearch(page: 1);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _currentPage < _lastPage) {
        _loadMore();
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final data = await _skillService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(page: 1);
    });
  }

  Future<void> _performSearch({int page = 1}) async {
    if (!mounted) return;

    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _isSearching = false;
        if (query.isEmpty) {
          _searchError = null;
        } else {
          _searchError = 'Please enter at least 2 characters to search.';
        }
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final typeParam = _selectedType == 'all' ? null : _selectedType;
      final response = await _skillService.searchSkills(
        query: query,
        categoryId: _selectedCategoryId,
        type: typeParam,
        page: page,
      );

      if (mounted) {
        setState(() {
          _results = response.results;
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.toString().replaceAll('Exception: ', '');
          _isSearching = false;
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
      final typeParam = _selectedType == 'all' ? null : _selectedType;
      final response = await _skillService.searchSkills(
        query: _searchController.text.trim(),
        categoryId: _selectedCategoryId,
        type: typeParam,
        page: nextPage,
      );

      if (mounted) {
        setState(() {
          _results.addAll(response.results);
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
            content: Text('Failed to load more results: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
        );
      }
    }
  }

  Future<void> _contactUser(SearchResultModel result) async {
    final swapRequestProvider = context.read<SwapRequestProvider>();
    final acceptedRequest = swapRequestProvider.getAcceptedRequestWithUser(result.userId);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (acceptedRequest == null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Chatting is only allowed once a Swap Request has been accepted.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
      return;
    }

    setState(() {
      _isInitiatingChat = true;
      _chattingUserId = result.userId;
    });
    final chatProvider = context.read<ChatProvider>();
    final navigator = Navigator.of(context);

    try {
      final conversation = await chatProvider.getOrCreateAndOpenConversation(result.userId, acceptedRequest.id);
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
          content: Text('Failed to open chat: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }

  void _viewDetails(SearchResultModel result, SearchSkillModel skill) {
    Navigator.pushNamed(
      context,
      '/skill-details',
      arguments: {
        'result': result,
        'skill': skill,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Advanced Search',
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
        child: Column(
          children: [
            _buildSearchInputSection(),
            _buildFilterSection(),
            Expanded(
              child: _buildResultsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInputSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: AppShadows.subtle,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search for skills or users...',
            prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppColors.textHint),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textHint),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch(page: 1);
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type Filters (All, Teach, Learn)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
          child: Row(
            children: [
              Text(
                'Type: ',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              _buildTypeChip('All', 'all'),
              const SizedBox(width: 8),
              _buildTypeChip('Teach', 'teach'),
              const SizedBox(width: 8),
              _buildTypeChip('Learn', 'learn'),
            ],
          ),
        ),

        // Category Filters
        if (!_isLoadingCategories && _categories.isNotEmpty)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryChip(
                    label: 'All Categories',
                    isSelected: _selectedCategoryId == null,
                    onSelected: (_) {
                      setState(() => _selectedCategoryId = null);
                      _performSearch(page: 1);
                    },
                  );
                }
                final category = _categories[index - 1];
                final isSelected = _selectedCategoryId == category.id;
                return _buildCategoryChip(
                  label: category.name,
                  isSelected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategoryId = selected ? category.id : null);
                    _performSearch(page: 1);
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        const Divider(color: AppColors.divider, height: 1),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required void Function(bool) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: AppColors.primaryLight,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedType = value);
          _performSearch(page: 1);
        }
      },
      selectedColor: AppColors.primaryLight,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildResultsSection() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_searchError != null) {
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
                  size: 40,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Search Error',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _searchError!,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.search,
                  color: AppColors.primary,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Explore Skills & Users',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter a keyword (at least 2 characters) to find matching skills to teach or learn.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.searchX,
                  color: AppColors.textHint,
                  size: 56,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No Results Found',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try modifying your filters or search keywords.',
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
      itemCount: _results.length + 1,
      itemBuilder: (context, index) {
        if (index == _results.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : const SizedBox.shrink();
        }

        final result = _results[index];
        final isMe = currentProfile.name.toLowerCase().trim() == result.name.toLowerCase().trim();

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
                // Top Info
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/profile',
                            arguments: {
                              'userId': result.userId,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryLight,
                                foregroundImage: result.profilePicture.isNotEmpty
                                    ? NetworkImage(result.profilePicture)
                                    : null,
                                onForegroundImageError: result.profilePicture.isNotEmpty
                                    ? (exception, stackTrace) {
                                        debugPrint('Failed to load profile image: $exception');
                                      }
                                    : null,
                                child: Text(
                                  result.name.isNotEmpty ? result.name[0].toUpperCase() : '?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
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
                                            result.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isMe)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                            ),
                                            child: Text(
                                              'You',
                                              style: AppTextStyles.labelSmall.copyWith(
                                                fontSize: 10,
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.star, color: Colors.amber, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          result.averageRating.toStringAsFixed(1),
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        const Icon(LucideIcons.shieldCheck, color: AppColors.success, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Trust: ${result.trustScore % 1 == 0 ? result.trustScore.toInt().toString() : result.trustScore.toStringAsFixed(2)}',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isMe)
                      IconButton(
                        icon: _isInitiatingChat && _chattingUserId == result.userId
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Icon(LucideIcons.messageCircle, color: AppColors.primary, size: 22),
                        onPressed: _isInitiatingChat ? null : () => _contactUser(result),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // List of Skills
                Text(
                  'Matching Skills:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ...result.skills.map((skill) {
                  final isTeach = skill.type.toLowerCase() == 'teach';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                skill.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isTeach ? const Color(0xFFE2F0D9) : const Color(0xFFFFF2CC),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  ),
                                  child: Text(
                                    isTeach ? 'TEACH' : 'LEARN',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isTeach ? const Color(0xFF385723) : const Color(0xFF7F6000),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  ),
                                  child: Text(
                                    skill.level.toUpperCase(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 9,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (skill.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            skill.description,
                            style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => _viewDetails(result, skill),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Details',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
