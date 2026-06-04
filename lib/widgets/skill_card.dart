gitimport 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SkillCard extends StatelessWidget {
  final String category;
  final String name;
  final String type;
  final VoidCallback? onViewDetails;

  const SkillCard({
    super.key,
    required this.category,
    required this.name,
    required this.type,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: AppTextStyles.labelSmall),

            const SizedBox(height: 4),

            Text(name, style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),

            const SizedBox(height: 8),

            Text(type, style: AppTextStyles.bodyMedium),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onViewDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  minimumSize: const Size(100, 36),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
