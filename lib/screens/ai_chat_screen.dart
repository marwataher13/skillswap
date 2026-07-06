import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_icon_painter.dart';
import '../providers/assistant_provider.dart';
import '../models/assistant_model.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseOpacity = Tween<double>(begin: 0.12, end: 0.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fetch conversation list on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssistantProvider>(context, listen: false).loadConversations();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final provider = Provider.of<AssistantProvider>(context);

    // Scroll to bottom when new messages arrive or loading states change
    if (provider.messages.isNotEmpty || provider.isLoading) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SkillSwap AI',
          style: AppTextStyles.headlineMedium.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(LucideIcons.history, color: c.textPrimary),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: c.divider,
            height: 1.0,
          ),
        ),
      ),
      endDrawer: _buildHistoryDrawer(context, provider, c),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages list or welcome greeting screen
            Expanded(
              child: provider.messages.isEmpty
                  ? _buildWelcomeScreen(c)
                  : _buildMessageList(context, provider, c),
            ),
            
            // Follow-up suggestion chips
            if (provider.followUps.isNotEmpty && !provider.isLoading)
              _buildFollowUps(context, provider, c),

            // User input section at bottom
            _buildInputSection(context, provider, c),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(AppColorsExtension c) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing Futuristic AI Icon Circle
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse ring
                    Transform.scale(
                      scale: _pulseScale.value,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.primary.withValues(
                            alpha: _pulseOpacity.value,
                          ),
                        ),
                      ),
                    ),
                    // Core Glow
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.surface,
                        boxShadow: AppShadows.card,
                        border: Border.all(
                          color: c.border.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(44, 44),
                          painter: AiIconPainter(color: c.primary),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // SkillSwap AI Title
            Text(
              'SkillSwap AI',
              style: AppTextStyles.displayMedium.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Subtitle
            Text(
              'Your intelligent career and learning assistant.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            // Tips / Starter prompt suggestion
            GestureDetector(
              onTap: () {
                Provider.of<AssistantProvider>(context, listen: false)
                    .sendMessage("I don't know what career suits me");
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.radiusMd,
                  ),
                  border: Border.all(
                    color: c.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sparkles, color: c.primary, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      "Start Career Assessment",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(
      BuildContext context, AssistantProvider provider, AppColorsExtension c) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.messages.length) {
          // Loading message
          return _buildLoadingBubble(c);
        }

        final msg = provider.messages[index];
        final isUser = msg.role == 'user';

        return Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: c.surface,
                    child: CustomPaint(
                      size: const Size(16, 16),
                      painter: AiIconPainter(color: c.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: isUser ? c.primary : c.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppSpacing.radiusMd),
                        topRight: const Radius.circular(AppSpacing.radiusMd),
                        bottomLeft: isUser
                            ? const Radius.circular(AppSpacing.radiusMd)
                            : Radius.zero,
                        bottomRight: isUser
                            ? Radius.zero
                            : const Radius.circular(AppSpacing.radiusMd),
                      ),
                      boxShadow: AppShadows.card,
                      border: isUser
                          ? null
                          : Border.all(
                              color: c.border.withValues(alpha: 0.3),
                            ),
                    ),
                    child: Text(
                      msg.content,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isUser ? Colors.white : c.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Intent-specific rendering under assistant bubbles (only show for last message)
            if (!isUser && index == provider.messages.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: AppSpacing.md),
                child: _buildIntentDetails(context, msg, provider, c),
              )
            else if (!isUser)
              const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

  Widget _buildLoadingBubble(AppColorsExtension c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: c.surface,
            child: CustomPaint(
              size: const Size(16, 16),
              painter: AiIconPainter(color: c.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: c.border.withValues(alpha: 0.3)),
            ),
            child: SizedBox(
              width: 24,
              height: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary.withValues(alpha: 0.7),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntentDetails(
      BuildContext context, AiMessage msg, AssistantProvider provider, AppColorsExtension c) {
    final intent = msg.intent ?? provider.currentIntent;

    if (intent == 'career_discovery') {
      if (provider.careerRecommendations.isEmpty) {
        return RiasecQuestionnaire(
          onSubmit: (scores) {
            provider.submitAssessment(scores);
          },
        );
      } else {
        return _buildCareerRecommendations(context, provider.careerRecommendations, c);
      }
    } else if (intent == 'skill_gap' && provider.skillGap != null) {
      return _buildSkillGapWidget(context, provider.skillGap!, c);
    } else if (intent == 'mentor_recommendation' && provider.mentors.isNotEmpty) {
      return _buildMentorsWidget(context, provider.mentors, c);
    } else if (intent == 'roadmap' && provider.roadmap.isNotEmpty) {
      return _buildRoadmapWidget(context, provider.roadmap, c);
    }

    return const SizedBox.shrink();
  }

  Widget _buildCareerRecommendations(
      BuildContext context, List<CareerRecommendation> recommendations, AppColorsExtension c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            'Recommended Careers:',
            style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
          ),
        ),
        ...recommendations.map((rec) {
          return Card(
            color: c.surface,
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              side: BorderSide(color: c.border.withValues(alpha: 0.3)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              onTap: () {
                Provider.of<AssistantProvider>(context, listen: false)
                    .sendMessage('I want to become a ${rec.career}');
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        rec.career,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${rec.confidence.toStringAsFixed(0)}% match',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        })
      ],
    );
  }

  Widget _buildSkillGapWidget(BuildContext context, SkillGap gap, AppColorsExtension c) {
    return Card(
      color: c.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: c.border.withValues(alpha: 0.3)),
      ),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Skill Gap Analysis',
                  style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${gap.matchPercentage.toStringAsFixed(0)}% Match',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: c.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Required Skills:',
              style: AppTextStyles.bodyLarge.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: gap.requiredSkills.map((s) {
                return Chip(
                  backgroundColor: c.inputFill,
                  label: Text(s, style: TextStyle(color: c.textPrimary)),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Missing Skills:',
              style: AppTextStyles.bodyLarge.copyWith(
                color: c.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            gap.missingSkills.isEmpty
                ? Text('None! You have all required skills.', style: TextStyle(color: c.success))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: gap.missingSkills.map((s) {
                      return Chip(
                        backgroundColor: c.error.withValues(alpha: 0.1),
                        side: BorderSide(color: c.error.withValues(alpha: 0.3)),
                        label: Text(s, style: TextStyle(color: c.error)),
                      );
                    }).toList(),
                  ),
            if (gap.roadmap.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Roadmap Steps:',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...gap.roadmap.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: c.primary,
                        child: Text(
                          '$idx',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step.description,
                              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                            ),
                            if (step.skills.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: step.skills.map((s) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      s,
                                      style: TextStyle(color: c.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (gap.mentors.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Recommended Mentors:',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...gap.mentors.map((mentor) {
                return Card(
                  color: c.inputFill,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mentor.name,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Matching Skills: ${mentor.matchingSkills.join(', ')}',
                                style: AppTextStyles.labelSmall.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${mentor.matchScore.toStringAsFixed(0)}% Score',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMentorsWidget(BuildContext context, List<MentorRecommendation> mentors, AppColorsExtension c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            'Recommended Mentors:',
            style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
          ),
        ),
        ...mentors.map((mentor) {
          return Card(
            color: c.surface,
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              side: BorderSide(color: c.border.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentor.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Matching Skills: ${mentor.matchingSkills.join(', ')}',
                          style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${mentor.matchScore.toStringAsFixed(0)}% score',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        })
      ],
    );
  }

  Widget _buildRoadmapWidget(BuildContext context, List<RoadmapStep> roadmap, AppColorsExtension c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            'Your Custom Learning Roadmap:',
            style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
          ),
        ),
        ...roadmap.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final step = entry.value;
          return Card(
            color: c.surface,
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              side: BorderSide(color: c.border.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: c.primary,
                    child: Text(
                      '$idx',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                        ),
                        if (step.skills.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: step.skills.map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(color: c.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        })
      ],
    );
  }

  Widget _buildFollowUps(
      BuildContext context, AssistantProvider provider, AppColorsExtension c) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: provider.followUps.length,
        itemBuilder: (context, idx) {
          final suggestion = provider.followUps[idx];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: c.surface,
              side: BorderSide(color: c.primary.withValues(alpha: 0.4)),
              label: Text(
                suggestion,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: c.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                provider.sendMessage(suggestion);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection(
      BuildContext context, AssistantProvider provider, AppColorsExtension c) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(color: c.divider, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        12,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !provider.isLoading,
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  provider.sendMessage(text);
                  _inputController.clear();
                }
              },
              decoration: InputDecoration(
                hintText: 'Ask me anything about learning or skills...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: c.textHint.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                suffixIcon: Icon(
                  LucideIcons.sparkles,
                  color: c.primary.withValues(alpha: 0.6),
                  size: 18,
                ),
                filled: true,
                fillColor: c.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  borderSide: BorderSide(color: c.border.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  borderSide: BorderSide(color: c.primary, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  borderSide: BorderSide(color: c.border.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: provider.isLoading
                ? null
                : () {
                    final text = _inputController.text;
                    if (text.trim().isNotEmpty) {
                      provider.sendMessage(text);
                      _inputController.clear();
                    }
                  },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: provider.isLoading
                    ? c.surfaceVariant.withValues(alpha: 0.5)
                    : c.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(
      BuildContext context, AssistantProvider provider, AppColorsExtension c) {
    return Drawer(
      backgroundColor: c.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chat History',
                    style: AppTextStyles.headlineMedium.copyWith(color: c.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.plusCircle, color: c.primary),
                    onPressed: () {
                      provider.startNewConversation();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: provider.isLoading && provider.conversations.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.conversations.isEmpty
                      ? Center(
                          child: Text(
                            'No history yet.',
                            style: AppTextStyles.bodyMedium.copyWith(color: c.textHint),
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.conversations.length,
                          itemBuilder: (context, index) {
                            final conv = provider.conversations[index];
                            final isSelected = provider.conversationId == conv.id;
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: c.surfaceVariant,
                              title: Text(
                                conv.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: isSelected ? c.primary : c.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                '${conv.messagesCount} messages',
                                style: AppTextStyles.labelSmall.copyWith(color: c.textSecondary),
                              ),
                              trailing: IconButton(
                                icon: Icon(LucideIcons.trash2, color: c.error, size: 18),
                                onPressed: () {
                                  provider.deleteConversation(conv.id);
                                },
                              ),
                              onTap: () {
                                provider.selectConversation(conv.id);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiasecQuestionnaire extends StatefulWidget {
  final Function(Map<String, int>) onSubmit;
  const RiasecQuestionnaire({super.key, required this.onSubmit});

  @override
  State<RiasecQuestionnaire> createState() => _RiasecQuestionnaireState();
}

class _RiasecQuestionnaireState extends State<RiasecQuestionnaire> {
  final Map<String, int> _scores = {
    'interest_Realistic': 3,
    'interest_Investigative': 3,
    'interest_Artistic': 3,
    'interest_Social': 3,
    'interest_Enterprising': 3,
    'interest_Conventional': 3,
  };

  final Map<String, String> _labels = {
    'interest_Realistic': 'Realistic: Do you like working with hands, tools, machines, or animals?',
    'interest_Investigative': 'Investigative: Do you like observing, learning, analyzing, and solving problems?',
    'interest_Artistic': 'Artistic: Do you like creative activities like art, music, drama, or writing?',
    'interest_Social': 'Social: Do you like helping, teaching, counseling, or curing people?',
    'interest_Enterprising': 'Enterprising: Do you like leading, managing, persuading, or selling things?',
    'interest_Conventional': 'Conventional: Do you like organizing, record-keeping, and working with data/numbers?',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Card(
      color: c.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: c.border.withValues(alpha: 0.3)),
      ),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Career Assessment Questionnaire',
              style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Rate your level of interest from 1 (lowest) to 5 (highest):',
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
            ),
            const Divider(height: 24),
            ..._scores.keys.map((key) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labels[key]!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final val = index + 1;
                      final isSelected = _scores[key] == val;
                      return ChoiceChip(
                        label: Text('$val'),
                        selected: isSelected,
                        selectedColor: c.primary,
                        backgroundColor: c.inputFill,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : c.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _scores[key] = val;
                            });
                          }
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            }),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                onPressed: () => widget.onSubmit(_scores),
                child: const Text('Submit Assessment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
