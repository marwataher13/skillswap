import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/skill_card_data.dart';
import 'package:skillswap/models/search_result_model.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:skillswap/screens/chat_messages_screen.dart';
import 'package:skillswap/services/chat_service.dart';
import 'package:skillswap/theme/app_theme.dart';

class SkillDetailsScreen extends StatefulWidget {
  const SkillDetailsScreen({super.key});

  @override
  State<SkillDetailsScreen> createState() => _SkillDetailsScreenState();
}

class _SkillDetailsScreenState extends State<SkillDetailsScreen> {
  final ChatService _chatService = ChatService();
  bool _isInitiatingChat = false;

  Future<void> _contactOwner(BuildContext context, int ownerId, String ownerName) async {
    setState(() => _isInitiatingChat = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final conversation = await _chatService.getOrCreateConversation(ownerId);
      if (!mounted) return;
      setState(() => _isInitiatingChat = false);

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatMessagesScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitiatingChat = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    SkillCardData? defaultSkill;
    SearchResultModel? searchResult;
    SearchSkillModel? searchSkill;

    if (args is SkillCardData) {
      defaultSkill = args;
    } else if (args is Map<String, dynamic>) {
      searchResult = args['result'] as SearchResultModel?;
      searchSkill = args['skill'] as SearchSkillModel?;
    }

    final category = defaultSkill?.category ?? searchSkill?.category ?? 'General';
    final name = defaultSkill?.name ?? searchSkill?.name ?? 'Skill Name';
    final type = defaultSkill?.type ?? searchSkill?.type ?? 'teach';
    final level = defaultSkill?.level ?? searchSkill?.level ?? '';
    final description = defaultSkill?.description ?? searchSkill?.description ?? 'No description provided for this skill.';

    final owner = searchResult;
    final hasOwner = owner != null;
    final currentProfile = context.watch<ProfileProvider>().profile;
    final isMe = hasOwner && currentProfile.name.toLowerCase().trim() == owner.name.toLowerCase().trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Skill Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Skill Main Header ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (level.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: Text(
                                level.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: type.toLowerCase() == 'teach'
                                  ? const Color(0xFF4CAF50).withValues(alpha: 0.9)
                                  : const Color(0xFF2196F3).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Skill Description Section ───
            Text(
              'About this Skill',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: AppShadows.card,
              ),
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Owner Profile Card (if SearchResultModel was passed) ───
            if (owner != null) ...[
              Text(
                'Offered By',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    // Owner Avatar
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.gradientStart, AppColors.gradientEnd],
                        ),
                      ),
                      child: owner.profilePicture.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                owner.profilePicture,
                                headers: const {'ngrok-skip-browser-warning': 'true'},
                                width: 58,
                                height: 58,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _initialsWidget(owner.name),
                              ),
                            )
                          : _initialsWidget(owner.name),
                    ),
                    const SizedBox(width: 16),

                    // Owner Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            owner.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.star,
                                size: 14,
                                color: AppColors.caramelRoast,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                owner.averageRating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                ),
                                child: Text(
                                  'Score: ${owner.trustScore}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mochaBean,
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
              ),
              const SizedBox(height: 32),
            ],

            // ─── Contact Action Button ───
            if (owner != null && !isMe) ...[
              _isInitiatingChat
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _contactOwner(
                          context,
                          owner.userId,
                          owner.name,
                        ),
                        icon: const Icon(LucideIcons.messageSquare, size: 20, color: Colors.white),
                        label: Text(
                          'Contact Expert',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                        ),
                      ),
                    ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _initialsWidget(String name) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
