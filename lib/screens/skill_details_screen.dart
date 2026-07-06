import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/skill_card_data.dart';
import 'package:skillswap/models/search_result_model.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:skillswap/providers/chat_provider.dart';
import 'package:skillswap/providers/swap_request_provider.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'package:skillswap/utils/url_utils.dart';
import 'package:skillswap/widgets/send_swap_request_sheet.dart';
import 'package:skillswap/screens/chat_messages_screen.dart';

class SkillDetailsScreen extends StatefulWidget {
  const SkillDetailsScreen({super.key});

  @override
  State<SkillDetailsScreen> createState() => _SkillDetailsScreenState();
}

class _SkillDetailsScreenState extends State<SkillDetailsScreen> {
  bool _isInitiatingChat = false;

  Future<void> _startChat(BuildContext context, SearchResultModel owner, int acceptedRequestId) async {
    setState(() => _isInitiatingChat = true);
    final chatProvider = context.read<ChatProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = context.appColors.error;

    try {
      final conversation = await chatProvider.getOrCreateAndOpenConversation(owner.userId, acceptedRequestId);
      if (!mounted) return;
      setState(() => _isInitiatingChat = false);
      navigator.push(
        MaterialPageRoute(builder: (_) => ChatMessagesScreen(conversation: conversation)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitiatingChat = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
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
    final swapRequestProvider = context.watch<SwapRequestProvider>();
    final acceptedRequest = hasOwner ? swapRequestProvider.getAcceptedRequestWithUser(owner.userId) : null;
    final hasAcceptedRequest = acceptedRequest != null;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Skill Details',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.gradientStart, c.gradientEnd],
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
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: Colors.white, letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
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
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
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
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('About this Skill', style: AppTextStyles.titleMedium),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: AppShadows.card,
              ),
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w400, color: c.textPrimary, height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (owner != null) ...[
              Text('Offered By', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                onTap: () => Navigator.pushNamed(context, '/profile', arguments: {'userId': owner.userId}),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [c.gradientStart, c.gradientEnd]),
                        ),
                        child: owner.profilePicture.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  owner.profilePicture,
                                  headers: const {'ngrok-skip-browser-warning': 'true'},
                                  width: 58, height: 58, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _initialsText(owner.name),
                                ),
                              )
                            : _initialsText(owner.name),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              owner.name,
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(LucideIcons.star, size: 14, color: c.caramelRoast),
                                const SizedBox(width: 4),
                                Text(
                                  owner.averageRating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: c.primaryLight,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  ),
                                  child: Text(
                                    'Score: ${owner.trustScore % 1 == 0 ? owner.trustScore.toInt().toString() : owner.trustScore.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: c.mochaBean),
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
              ),
              const SizedBox(height: 32),
            ],

            if (owner != null && !isMe) ...[
              if (hasAcceptedRequest) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isInitiatingChat ? null : () => _startChat(context, owner, acceptedRequest.id),
                          icon: _isInitiatingChat
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
                                )
                              : Icon(LucideIcons.messageCircle, size: 20, color: c.primary),
                          label: _isInitiatingChat
                              ? const SizedBox.shrink()
                              : Text(
                                  'Chat',
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: c.primary),
                                ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: c.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => SendSwapRequestSheet.show(
                            context,
                            receiverId: owner.userId,
                            receiverName: owner.name,
                            requestedSkillName: name,
                          ),
                          icon: const Icon(LucideIcons.repeat, size: 20, color: Colors.white),
                          label: Text(
                            'Swap Request',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.primary, elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => SendSwapRequestSheet.show(
                      context,
                      receiverId: owner.userId,
                      receiverName: owner.name,
                      requestedSkillName: name,
                    ),
                    icon: const Icon(LucideIcons.repeat, size: 20, color: Colors.white),
                    label: Text(
                      'Swap Request',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary, elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _initialsText(String name) {
    return Center(
      child: Text(
        initialsOf(name),
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}
