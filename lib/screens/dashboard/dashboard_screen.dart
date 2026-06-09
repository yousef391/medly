import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = MockData.stats;
    final recentLogs = MockData.recentLogs;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لوحة التحكم',
                          style:
                              Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SMS Sender Dashboard',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    // Server status indicator
                    _buildServerStatus(context),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
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
                        value: stats.totalSmsSent.toString(),
                        label: 'SMS envoyés',
                        color: AppColors.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: Icons.error_outline_rounded,
                        value: stats.totalSmsFailed.toString(),
                        label: 'Échoués',
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
                        icon: Icons.pending_outlined,
                        value: stats.totalSmsPending.toString(),
                        label: 'En attente',
                        color: AppColors.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: Icons.webhook_rounded,
                        value: stats.totalWebhooksReceived.toString(),
                        label: 'Webhooks reçus',
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Today's Summary Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildTodaySummary(context, stats),
          ),
        ),

        // Recent Activity Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final log = recentLogs[index];
                return _buildSmsLogItem(context, log);
              },
              childCount: recentLogs.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServerStatus(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 30,
      borderColor: AppColors.accentGreen.withValues(alpha: 0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulsingDot(color: AppColors.accentGreen, size: 8),
          const SizedBox(width: 8),
          Text(
            'Webhook actif',
            style: TextStyle(
              color: AppColors.accentGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context, DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Aujourd'hui",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 28,
            ),
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
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
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
    switch (log.eventType) {
      case WebhookEventType.atWilaya:
        eventColor = AppColors.statusAtWilaya;
        break;
      case WebhookEventType.outForDelivery:
        eventColor = AppColors.statusOutDelivery;
        break;
      default:
        eventColor = AppColors.textMuted;
    }

    final timeAgo = _getTimeAgo(log.timestamp);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: customer name + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        log.eventType == WebhookEventType.atWilaya
                            ? Icons.location_on_outlined
                            : Icons.local_shipping_outlined,
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
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 14,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.phoneNumber,
                            style: Theme.of(context).textTheme.bodySmall,
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
          const SizedBox(height: 12),

          // Tracking & Event info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
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
          const SizedBox(height: 8),

          // Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_city_rounded,
                    color: AppColors.textMuted,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    log.wilaya,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                timeAgo,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
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
