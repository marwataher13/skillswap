import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: _buildAppBar(context, c),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(c),
            const SizedBox(height: 24),

            // Our Mission Section
            _buildMissionSection(c),
            const SizedBox(height: 24),

            // Key Features Section
            _buildSectionHeader(c, 'KEY FEATURES'),
            const SizedBox(height: 12),
            _buildFeaturesList(c),
            const SizedBox(height: 24),

            // Why SkillSwap Section
            _buildSectionHeader(c, 'WHY SKILLSWAP?'),
            const SizedBox(height: 12),
            _buildWhySection(c),
            const SizedBox(height: 32),

            // App Info Section
            _buildAppInfoSection(c),
            const SizedBox(height: 32),

            // Footer Quote
            _buildFooterQuote(c),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppColorsExtension c) {
    return AppBar(
      backgroundColor: c.background,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.textPrimary, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'About SkillSwap',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(AppColorsExtension c, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: c.primary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildWelcomeSection(AppColorsExtension c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.sparkles, color: c.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome to SkillSwap! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'SkillSwap is a community-driven platform where people can exchange skills, connect with others, and learn without the cost of traditional courses. Every user can be both a learner and a teacher.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.6,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(AppColorsExtension c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OUR MISSION',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Our mission is to make learning more accessible by connecting people who want to share knowledge and grow together through skill exchange.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.6,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(AppColorsExtension c) {
    final List<_FeatureItem> features = [
      const _FeatureItem(
        icon: Icons.sync,
        title: 'Skill Exchange',
        description: 'Trade your expertise with others in a mutual learning setup.',
      ),
      const _FeatureItem(
        icon: Icons.person_outline,
        title: 'Personalized User Profiles',
        description: 'Showcase your skills, bios, portfolios, and teaching ratings.',
      ),
      const _FeatureItem(
        icon: Icons.chat_bubble_outline,
        title: 'Real-Time Chat',
        description: 'Connect and chat with other members instantly.',
      ),
      const _FeatureItem(
        icon: Icons.calendar_month_outlined,
        title: 'Time Slot Scheduling',
        description: 'Define and select availability slots for meeting times.',
      ),
      const _FeatureItem(
        icon: Icons.handshake_outlined,
        title: 'Swap Requests',
        description: 'Send and receive skill-swapping proposals seamlessly.',
      ),
      const _FeatureItem(
        icon: Icons.star_outline,
        title: 'Ratings & Reviews',
        description: 'Build community trust with feedback and swap ratings.',
      ),
      const _FeatureItem(
        icon: Icons.search,
        title: 'Discover Skilled People',
        description: 'Browse top teachers, search categories, or apply filters.',
      ),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final f = features[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(f.icon, size: 20, color: c.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWhySection(AppColorsExtension c) {
    final reasons = [
      'Learn new skills for free through exchange.',
      'Share your expertise with others.',
      'Build meaningful connections.',
      'Grow together as a community.',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: reasons.map((reason) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: c.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reason,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.4,
                      color: c.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppInfoSection(AppColorsExtension c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: c.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
              Text(
                '1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: c.primary.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Developed with ',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: c.textSecondary,
                ),
              ),
              const Icon(Icons.favorite, color: Colors.red, size: 14),
              Text(
                ' by the SkillSwap Team.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterQuote(AppColorsExtension c) {
    return Center(
      child: Column(
        children: [
          Text(
            '"Learn. Share. Grow Together."',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: c.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
