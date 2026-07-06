import 'package:flutter/material.dart';
import 'package:skillswap/models/category_model.dart';
import 'package:skillswap/models/skill_card_data.dart';
import 'package:skillswap/services/auth_service.dart';
import 'package:skillswap/services/skill_service.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'package:skillswap/widgets/add_skill_bottom_sheet.dart';
import 'package:skillswap/widgets/manage_skill_bottom_sheet.dart';
import 'package:skillswap/widgets/skill_item_tile.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key});

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen>
    with SingleTickerProviderStateMixin {
  final SkillService _skillService = SkillService();

  List<SkillCardData> _skills = [];
  List<CategoryModel> _categories = [];

  bool _isLoading = true;
  String? _error;

  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeOutBack,
    );
    _loadData();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      final results = await Future.wait([
        _skillService.fetchMySkills(token: token ?? ''),
        _skillService.fetchCategories(),
      ]);

      if (!mounted) return;
      setState(() {
        _skills = results[0] as List<SkillCardData>;
        _categories = results[1] as List<CategoryModel>;
        _isLoading = false;
      });
      _fabAnimController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (e.toString().contains('401')) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showAddSkillSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSkillBottomSheet(categories: _categories, onSaved: _loadData),
    );
  }

  void _showManageSkillSheet(SkillCardData skill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManageSkillBottomSheet(
        skill: skill,
        categories: _categories,
        onUpdated: _loadData,
        onDeleted: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(c),
            Expanded(child: _buildBody(c)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: _buildFAB(c),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Skills',
            style: AppTextStyles.displayMedium.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isLoading
                ? 'Loading...'
                : '${_skills.length} skill${_skills.length == 1 ? '' : 's'}',
            style: AppTextStyles.bodyMedium.copyWith(color: c.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppColorsExtension c) {
    if (_isLoading) return _buildLoading(c);
    if (_error != null) return _buildError(c);
    if (_skills.isEmpty) return _buildEmpty(c);
    return _buildSkillList(c);
  }

  Widget _buildLoading(AppColorsExtension c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: c.primary, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text('Loading your skills...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildError(AppColorsExtension c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 32, color: c.error),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong', style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Could not load your skills',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension c) {
    return Center(
      child: AnimatedOpacity(
        opacity: _skills.isEmpty ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.gradientStart, c.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text('No skills yet', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Add your first skill to start\nconnecting with others!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillList(AppColorsExtension c) {
    return RefreshIndicator(
      color: c.primary,
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: _skills.length,
        itemBuilder: (context, index) {
          final skill = _skills[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + (index * 80)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SkillItemTile(
                skill: skill,
                onTap: () => _showManageSkillSheet(skill),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAB(AppColorsExtension c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: 190,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: _showAddSkillSheet,
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            'Add Skill',
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
