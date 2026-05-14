import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    
                    // ─── Search Bar ─────────────────────────────────────────
                    _buildSearchBar(),
                    
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Category List ──────────────────────────────────────
                    _buildCategoryList(),

                    const SizedBox(height: AppSpacing.lg),

                    // ─── Skill Cards List ───────────────────────────────────
                    _buildSkillCard(
                      image: 'assets/images/guitar.jpg', // استبدليها بمسار صورك
                      category: 'Creative',
                      title: 'Guitar Lessons',
                      exchange: 'in exchange for Spanish Tutoring',
                      user: 'Anna, 5 miles away',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSkillCard(
                      image: 'assets/images/camera.jpg',
                      category: 'Creative',
                      title: 'Photography Basics',
                      exchange: 'in exchange for Baking Lessons',
                      user: 'Mark, 2 miles away',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // ─── Bottom Navigation Bar ────────────────────────────────────────────
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
            backgroundImage: AssetImage('assets/images/user_avatar.jpg'), // صورة البروفايل
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppShadows.subtle,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search skills or members',
          prefixIcon: const Icon(LucideIcons.search, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final categories = ['Creative', 'Tech', 'Lifestyle', 'Business'];
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isFirst = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isFirst ? const Color(0xFFD7C4B7) : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                categories[index],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isFirst ? FontWeight.w600 : FontWeight.w400,
                  color: isFirst ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillCard({
    required String image,
    required String category,
    required String title,
    required String exchange,
    required String user,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8DDD6), // لون الكارد من الصورة
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
            child: Image.asset(image, height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: AppTextStyles.labelSmall),
                const SizedBox(height: 4),
                Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                Text(exchange, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(user, style: AppTextStyles.labelSmall),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7C4B7),
                        minimumSize: const Size(100, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('View S...', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
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
  }