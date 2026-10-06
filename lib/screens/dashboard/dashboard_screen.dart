import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/webhook_listener_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  DashboardStats _stats = const DashboardStats(
    totalSmsSent: 0,
    totalSmsFailed: 0,
    totalSmsPending: 0,
    totalWebhooksReceived: 0,
    todaySmsSent: 0,
    todayWebhooks: 0,
  );
  List<SmsLogEntry> _recentLogs = [];
  bool _loading = true;
  late AnimationController _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadData();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final stats = await SupabaseService.getDashboardStats();
      final logs = await SupabaseService.fetchSmsLogs();
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentLogs = logs.take(5).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Hero Header
          SliverToBoxAdapter(
            child: _buildHeroHeader(context),
          ),

          // Stats Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.send_rounded,
                          value: _stats.totalSmsSent.toString(),
                          label: 'SMS ENVOYÉS',
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.error_outline_rounded,
                          value: _stats.totalSmsFailed.toString(),
                          label: 'ÉCHOUÉS',
                          color: AppColors.accentRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.schedule_rounded,
                          value: _stats.totalSmsPending.toString(),
                          label: 'EN ATTENTE',
                          color: AppColors.accentOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.webhook_rounded,
                          value: _stats.totalWebhooksReceived.toString(),
                          label: 'WEBHOOKS',
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Today's Summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildTodaySummary(context, _stats),
            ),
          ),

          // Recent Activity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: SectionHeader(
                title: 'Activité récente',
                actionText: 'Voir tout',
                actionIcon: Icons.arrow_forward_ios,
                onAction: () {},
              ),
            ),
          ),

          // Recent SMS Logs
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: _loading
                ? SliverToBoxAdapter(
                    child: _buildLoadingState(),
                  )
                : _recentLogs.isEmpty
                    ? SliverToBoxAdapter(
                        child: _buildEmptyState(context),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final log = _recentLogs[index];
                            return _buildSmsLogItem(context, log);
                          },
                          childCount: _recentLogs.length,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final isListening = WebhookListenerService.isListening;

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _headerAnim,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _headerAnim,
          curve: Curves.easeOut,
        )),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceLight,
                AppColors.surface.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glowPrimary.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لوحة التحكم',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.8,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.heroGradient.createShader(bounds),
                        child: Text(
                          'SMS Sender Dashboard',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Server status pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isListening
                              ? AppColors.accentGreen
                              : AppColors.accentRed)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: (isListening
                                ? AppColors.accentGreen
                                : AppColors.accentRed)
                            .withValues(alpha: 0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isListening
                                  ? AppColors.accentGreen
                                  : AppColors.accentRed)
                              .withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PulsingDot(
                          color: isListening
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          size: 8,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isListening ? 'En ligne' : 'Arrêté',
                          style: TextStyle(
                            color: isListening
                                ? AppColors.accentGreen
                                : AppColors.accentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context, DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight.withValues(alpha: 0.9),
            AppColors.accent.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Content
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "📊  Aujourd'hui",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildTodayStat(
                          '${stats.todaySmsSent}',
                          'SMS envoyés',
                          Icons.send_rounded,
                        ),
                        const SizedBox(width: 32),
                        _buildTodayStat(
                          '${stats.todayWebhooks}',
                          'Webhooks',
                          Icons.webhook_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStat(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(
              width: double.infinity,
              height: 100,
              borderRadius: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceLight,
                    AppColors.surfaceElevated.withValues(alpha: 0.5),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.glowPrimary.withValues(alpha: 0.1),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Icon(
                Icons.inbox_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.5),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune activité',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Les SMS apparaîtront ici automatiquement',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsLogItem(BuildContext context, SmsLogEntry log) {
    Color statusColor;
    IconData statusIcon;
    switch (log.smsStatus) {
      case SmsStatus.sent:
        statusColor = AppColors.accentGreen;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case SmsStatus.failed:
        statusColor = AppColors.accentRed;
        statusIcon = Icons.error_outline_rounded;
        break;
      case SmsStatus.pending:
        statusColor = AppColors.accentOrange;
        statusIcon = Icons.schedule_rounded;
        break;
    }

    Color eventColor;
    IconData eventIcon;
    switch (log.eventType) {
      case WebhookEventType.atWilaya:
        eventColor = AppColors.statusAtWilaya;
        eventIcon = Icons.location_on_outlined;
        break;
      case WebhookEventType.outForDelivery:
        eventColor = AppColors.statusOutDelivery;
        eventIcon = Icons.local_shipping_outlined;
        break;
      default:
        eventColor = AppColors.textMuted;
        eventIcon = Icons.local_shipping_outlined;
    }

    final timeAgo = _getTimeAgo(log.timestamp);

    return GlassCard(
      glowColor: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            eventColor.withValues(alpha: 0.15),
                            eventColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: eventColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Icon(
                        eventIcon,
                        color: eventColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.customerName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            log.phoneNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: log.smsStatusLabel,
                color: statusColor,
                icon: statusIcon,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.tag, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        log.trackingId,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: log.eventTypeLabelFr,
                  color: eventColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_city_rounded,
                      color: AppColors.textMuted, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    log.wilaya,
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      color: AppColors.textMuted, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo,
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}
