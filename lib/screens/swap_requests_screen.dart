import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/swap_request_model.dart';
import '../providers/swap_request_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/swap_request_card.dart';
import 'swap_request_details_screen.dart';

class SwapRequestsScreen extends StatefulWidget {
  const SwapRequestsScreen({super.key});

  @override
  State<SwapRequestsScreen> createState() => _SwapRequestsScreenState();
}

class _SwapRequestsScreenState extends State<SwapRequestsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SwapRequestProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDetails(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SwapRequestDetailsScreen(requestId: id),
      ),
    );
  }

  void _showSnack(String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF16A34A) : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabViews()),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Swap Requests',
            style: AppTextStyles.displayMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Consumer<SwapRequestProvider>(
            builder: (_, provider, __) {
              if (provider.isLoading) {
                return Text(
                  'Loading…',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                );
              }
              final pending = provider.pendingReceivedCount;
              return Text(
                pending > 0
                    ? '$pending pending request${pending == 1 ? '' : 's'}'
                    : 'No pending requests',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: pending > 0
                      ? const Color(0xFFD97706)
                      : AppColors.textHint,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        unselectedLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: [
          Consumer<SwapRequestProvider>(
            builder: (_, provider, __) {
              final count = provider.pendingReceivedCount;
              return Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Received'),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      _Badge(count: count),
                    ],
                  ],
                ),
              );
            },
          ),
          const Tab(text: 'Sent'),
        ],
      ),
    );
  }

  // ── Tab views ─────────────────────────────────────────────────────────────

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        _RequestList(
          isSent: false,
          onDetails: _openDetails,
          onSnack: _showSnack,
        ),
        _RequestList(
          isSent: true,
          onDetails: _openDetails,
          onSnack: _showSnack,
        ),
      ],
    );
  }
}

// ── Notification badge ────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Reusable list for both tabs ───────────────────────────────────────────────

class _RequestList extends StatelessWidget {
  final bool isSent;
  final void Function(int id) onDetails;
  final void Function(String msg, {bool success}) onSnack;

  const _RequestList({
    required this.isSent,
    required this.onDetails,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SwapRequestProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) return _buildLoading();
        if (provider.error != null) return _buildError(context, provider);
        final list = isSent ? provider.sent : provider.received;
        if (list.isEmpty) return _buildEmpty();
        return _buildList(context, provider, list);
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError(BuildContext context, SwapRequestProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: provider.loadAll,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSent ? Icons.outbox_rounded : Icons.move_to_inbox_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSent ? 'No sent requests' : 'No received requests',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSent
                  ? 'Browse skills and send your first swap request!'
                  : 'When someone sends you a request\nit will appear here.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    SwapRequestProvider provider,
    List<SwapRequest> list,
  ) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final req = list[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 250 + index * 60),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - value)),
                child: child,
              ),
            ),
            child: SwapRequestCard(
              request: req,
              isSent: isSent,
              onTap: () => onDetails(req.id),
              onAccept: isSent
                  ? null
                  : () async {
                      final err = await provider.accept(req.id);
                      if (err == null) {
                        onSnack('Request accepted! 🎉', success: true);
                      } else {
                        onSnack(err, success: false);
                      }
                    },
              onReject: isSent
                  ? null
                  : () async {
                      final err = await provider.reject(req.id);
                      if (err == null) {
                        onSnack('Request rejected.', success: false);
                      } else {
                        onSnack(err, success: false);
                      }
                    },
              onCancel: !isSent
                  ? null
                  : () async {
                      final err = await provider.cancel(req.id);
                      if (err == null) {
                        onSnack('Request cancelled.', success: false);
                      } else {
                        onSnack(err, success: false);
                      }
                    },
            ),
          );
        },
      ),
    );
  }
}
