import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

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
      icon: LucideIcons.lock,
      label: 'Change Password',
      route: '/change-password',
    ),
  ];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Account Management ──
            _buildSectionLabel(context, 'ACCOUNT MANAGEMENT'),
            const SizedBox(height: 10),
            _buildSectionCard(context, _accountItems),

            const SizedBox(height: 28),

            // ── Privacy & Security ──
            _buildSectionLabel(context, 'PRIVACY & SECURITY'),
            const SizedBox(height: 10),
            _buildSectionCard(context, _privacyItems),

            const SizedBox(height: 28),

            // ── Appearance ──
            _buildSectionLabel(context, 'APPEARANCE'),
            const SizedBox(height: 10),
            _buildAppearanceCard(context),

            const SizedBox(height: 28),

            // ── App & Support ──
            _buildSectionLabel(context, 'APP & SUPPORT'),
            const SizedBox(height: 10),
            _buildSupportCard(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text(
        'Settings',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.1,
      ),
    );
  }

  // ── Generic section card ──────────────────────────────────────────────────

  Widget _buildSectionCard(BuildContext context, List<_SettingsItem> items) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
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
                onTap: () => Navigator.pushNamed(context, item.route),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 56,
                  endIndent: 0,
                  color: cs.primary.withValues(alpha: 0.08),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ── Appearance card (dark mode toggle) ───────────────────────────────────

  Widget _buildAppearanceCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.moon, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Dark Mode',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            Switch(
              value: isDark,
              onChanged: (_) => context.read<ThemeProvider>().toggle(),
              activeThumbColor: cs.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Support card (About + Log Out) ────────────────────────────────────────

  Widget _buildSupportCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _buildTile(
            context,
            icon: LucideIcons.info,
            label: 'About SkillSwap',
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            endIndent: 0,
            color: cs.primary.withValues(alpha: 0.08),
          ),
          _buildTile(
            context,
            icon: LucideIcons.logOut,
            label: 'Log Out',
            labelColor: cs.error,
            iconColor: cs.error,
            iconBgColor: cs.error.withValues(alpha: 0.08),
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
    final cs = Theme.of(context).colorScheme;
    final resolvedIconColor = iconColor ?? cs.primary;
    final resolvedIconBg = iconBgColor ?? cs.primary.withValues(alpha: 0.08);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
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
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: labelColor ?? cs.onSurface,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          backgroundColor: cs.surface,
          title: Text(
            'Log Out',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await AuthService.clearToken();
                if (!context.mounted) return;
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
                  color: cs.error,
                ),
              ),
            ),
          ],
        );
      },
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
