import 'package:flutter/material.dart';
import 'package:skillswap/models/skill_card_data.dart';
import 'package:skillswap/theme/app_theme.dart';

class SkillItemTile extends StatelessWidget {
  final SkillCardData skill;
  final VoidCallback onTap;

  const SkillItemTile({super.key, required this.skill, required this.onTap});

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
      case 'programming':
      case 'tech':
        return Icons.computer_rounded;
      case 'design':
      case 'art':
        return Icons.palette_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'language':
      case 'languages':
        return Icons.translate_rounded;
      case 'cooking':
      case 'food':
        return Icons.restaurant_rounded;
      case 'fitness':
      case 'sports':
        return Icons.fitness_center_rounded;
      case 'business':
      case 'finance':
        return Icons.business_center_rounded;
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'writing':
        return Icons.edit_note_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFFFF9800);
      case 'advanced':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFA38772);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    final typeColor = skill.type.toLowerCase() == 'teach'
        ? c.success
        : skill.type.toLowerCase() == 'learn'
            ? c.primary
            : c.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          splashColor: c.primaryLight.withValues(alpha: 0.4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppShadows.card,
              color: c.surface,
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.gradientStart, c.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(_categoryIcon(skill.category), color: Colors.white, size: 24),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (skill.category.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          skill.category,
                          style: AppTextStyles.labelSmall.copyWith(color: c.textHint),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge(
                            skill.type.isNotEmpty
                                ? skill.type[0].toUpperCase() + skill.type.substring(1)
                                : '',
                            typeColor,
                          ),
                          if (skill.level.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _buildBadge(
                              skill.level[0].toUpperCase() + skill.level.substring(1),
                              _levelColor(skill.level),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: c.background, shape: BoxShape.circle),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: c.textHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
