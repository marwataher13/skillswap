import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ── Data ──────────────────────────────────────────────────────────────────

  static const _accountItems = [
    _SettingsItem(
      icon: LucideIcons.user,
      label: 'Edit Profile',
      route: '/edit-profile',
    ),
  ];

  static const _privacyItems = [
    _SettingsItem(
      icon: LucideIcons.shieldOff,
      label: 'Blocked Users',
      route: '/blocked-users',
    ),
    _SettingsItem(
      icon: LucideIcons.lock,
      label: 'Change Password',
      route: '/change-password',
    ),
  ];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Account Management ──
            _buildSectionLabel('ACCOUNT MANAGEMENT'),
            const SizedBox(height: 10),
            _buildSectionCard(context, _accountItems),

            const SizedBox(height: 28),

            // ── Privacy & Security ──
            _buildSectionLabel('PRIVACY & SECURITY'),
            const SizedBox(height: 10),
            _buildSectionCard(context, _privacyItems),

            const SizedBox(height: 28),

            // ── App & Support ──
            _buildSectionLabel('APP & SUPPORT'),
            const SizedBox(height: 10),
            _buildSupportCard(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text(
        'Settings',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 1.1,
      ),
    );
  }

  // ── Generic section card ──────────────────────────────────────────────────

  Widget _buildSectionCard(BuildContext context, List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              _buildTile(
                context,
                icon: item.icon,
                label: item.label,
                onTap: () {
                  if (item.route == '/blocked-users') {
                    _showComingSoonSnackBar(context, item.label);
                  } else {
                    Navigator.pushNamed(context, item.route);
                  }
                },
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 56,
                  endIndent: 0,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ── Support card (About + Log Out) ────────────────────────────────────────

  Widget _buildSupportCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          // About SkillSwap
          _buildTile(
            context,
            icon: LucideIcons.info,
            label: 'About SkillSwap',
            onTap: () => _showComingSoonSnackBar(context, 'About SkillSwap'),
          ),

          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            endIndent: 0,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),

          // Log Out — red accent
          _buildTile(
            context,
            icon: LucideIcons.logOut,
            label: 'Log Out',
            labelColor: AppColors.error,
            iconColor: AppColors.error,
            iconBgColor: AppColors.error.withValues(alpha: 0.08),
            showChevron: false,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  // ── Single tile ───────────────────────────────────────────────────────────

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    Color? iconColor,
    Color? iconBgColor,
    bool showChevron = true,
  }) {
    final resolvedIconColor = iconColor ?? AppColors.primary;
    final resolvedIconBg =
        iconBgColor ?? AppColors.primary.withValues(alpha: 0.08);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: resolvedIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: resolvedIconColor),
            ),
            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: labelColor ?? AppColors.textPrimary,
                ),
              ),
            ),

            // Chevron
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }

  // ── Log out confirmation dialog ───────────────────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        backgroundColor: AppColors.surface,
        title: Text(
          'Log Out',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName feature coming soon! 🚀'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _SettingsItem {
  final IconData icon;
  final String label;
  final String route;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
