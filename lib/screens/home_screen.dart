import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skillswap/models/skill_card_data.dart';
import '../theme/app_theme.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/category_list.dart';
import '../widgets/skill_card.dart';
import '../services/skill_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _skillService = SkillService();
  List<SkillCardData> _skills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final skills = await _skillService.fetchSkills();
      if (mounted) {
        setState(() {
          _skills = skills;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load skills: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Custom AppBar ──────────────────────────────────────────────
            _buildAppBar(),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryDark,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSkills,
                      color: AppColors.primaryDark,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.md),

                            // ─── Search Bar ─────────────────────────────────────────
                            const HomeSearchBar(),

                            const SizedBox(height: AppSpacing.lg),

                            // ─── Category List ──────────────────────────────────────
                            const CategoryList(),

                            const SizedBox(height: AppSpacing.lg),

                            // ─── Skill Cards List ───────────────────────────────────
                            if (_skills.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: Center(
                                  child: Text(
                                    'No skills found.',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _skills.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final skill = _skills[index];
                                  return SkillCard(
                                    image: skill.image,
                                    category: skill.category,
                                    title: skill.title,
                                    exchange: skill.exchange,
                                    user: skill.user,
                                  );
                                },
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(
              'assets/images/user_avatar.jpg',
            ), // صورة البروفايل
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
