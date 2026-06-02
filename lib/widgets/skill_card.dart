import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SkillCard extends StatelessWidget {
  final String image;
  final String category;
  final String title;
  final String exchange;
  final String user;
  final VoidCallback? onViewDetails;

  const SkillCard({
    super.key,
    required this.image,
    required this.category,
    required this.title,
    required this.exchange,
    required this.user,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.border, // Using border color for card background
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
            child: Image.asset(
              image,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  exchange,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user,
                      style: AppTextStyles.labelSmall,
                    ),
                    ElevatedButton(
                      onPressed: onViewDetails ?? () {},
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
}
