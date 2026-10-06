import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class SmsLogsScreen extends StatefulWidget {
  const SmsLogsScreen({super.key});

  @override
  State<SmsLogsScreen> createState() => _SmsLogsScreenState();
}

class _SmsLogsScreenState extends State<SmsLogsScreen> {
  SmsStatus? _selectedFilter;
  WebhookEventType? _selectedEventFilter;
  final TextEditingController _searchController = TextEditingController();
  List<SmsLogEntry> _allLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      final logs = await SupabaseService.fetchSmsLogs();
      if (mounted) setState(() { _allLogs = logs; _loading = false; });
    } catch (e) {
      debugPrint('Error loading logs: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SmsLogEntry> get filteredLogs {
    var logs = _allLogs;
    if (_selectedFilter != null) {
      logs = logs.where((l) => l.smsStatus == _selectedFilter).toList();
    }
    if (_selectedEventFilter != null) {
      logs = logs.where((l) => l.eventType == _selectedEventFilter).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      logs = logs
          .where((l) =>
              l.customerName.toLowerCase().contains(query) ||
              l.phoneNumber.contains(query) ||
              l.trackingId.toLowerCase().contains(query))
          .toList();
    }
    return logs;
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'Journal SMS',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Historique des messages envoyés',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom, téléphone, tracking...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          color: AppColors.textMuted,
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Filter chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Tous',
                        _selectedFilter == null && _selectedEventFilter == null,
                        AppColors.primary,
                        () => setState(() {
                          _selectedFilter = null;
                          _selectedEventFilter = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Envoyés',
                        _selectedFilter == SmsStatus.sent,
                        AppColors.accentGreen,
                        () => setState(() {
                          _selectedFilter =
                              _selectedFilter == SmsStatus.sent ? null : SmsStatus.sent;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Échoués',
                        _selectedFilter == SmsStatus.failed,
                        AppColors.accentRed,
                        () => setState(() {
                          _selectedFilter = _selectedFilter == SmsStatus.failed
                              ? null
                              : SmsStatus.failed;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'En attente',
                        _selectedFilter == SmsStatus.pending,
                        AppColors.accentOrange,
                        () => setState(() {
                          _selectedFilter = _selectedFilter == SmsStatus.pending
                              ? null
                              : SmsStatus.pending;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'À votre wilaya',
                        _selectedEventFilter == WebhookEventType.atWilaya,
                        AppColors.statusAtWilaya,
                        () => setState(() {
                          _selectedEventFilter =
                              _selectedEventFilter == WebhookEventType.atWilaya
                                  ? null
                                  : WebhookEventType.atWilaya;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Sorti à livraison',
                        _selectedEventFilter == WebhookEventType.outForDelivery,
                        AppColors.statusOutDelivery,
                        () => setState(() {
                          _selectedEventFilter = _selectedEventFilter ==
                                  WebhookEventType.outForDelivery
                              ? null
                              : WebhookEventType.outForDelivery;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Results count
                Text(
                  '${filteredLogs.length} messages',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),

        // SMS Log entries
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          sliver: _loading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                )
              : filteredLogs.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(context),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final log = filteredLogs[index];
                          return _buildLogCard(context, log);
                        },
                        childCount: filteredLogs.length,
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.4) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, SmsLogEntry log) {
    Color statusColor;
    IconData statusIcon;
    switch (log.smsStatus) {
      case SmsStatus.sent:
        statusColor = AppColors.accentGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case SmsStatus.failed:
        statusColor = AppColors.accentRed;
        statusIcon = Icons.cancel_rounded;
        break;
      case SmsStatus.pending:
        statusColor = AppColors.accentOrange;
        statusIcon = Icons.schedule_rounded;
        break;
    }

    Color eventColor = log.eventType == WebhookEventType.atWilaya
        ? AppColors.statusAtWilaya
        : AppColors.statusOutDelivery;

    return GlassCard(
      onTap: () => _showLogDetail(context, log),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.customerName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    Text(
                      _formatTime(log.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      log.phoneNumber,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.tag, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.trackingId,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusBadge(label: log.eventTypeLabelFr, color: eventColor),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: log.wilaya,
                      color: AppColors.textSecondary,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sms_outlined,
                color: AppColors.textMuted,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun message trouvé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Essayez de modifier vos filtres',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDetail(BuildContext context, SmsLogEntry log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Détails du message',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),

                    // Info rows
                    _buildDetailRow(
                        'Client', log.customerName, Icons.person_outline),
                    _buildDetailRow(
                        'Téléphone', log.phoneNumber, Icons.phone_outlined),
                    _buildDetailRow('Tracking', log.trackingId, Icons.tag),
                    _buildDetailRow(
                        'Wilaya', log.wilaya, Icons.location_city_rounded),
                    _buildDetailRow(
                        'Événement', log.eventTypeLabelFr, Icons.event_note),
                    _buildDetailRow(
                        'Statut', log.smsStatusLabel, Icons.info_outline),
                    _buildDetailRow(
                        'Heure',
                        _formatTimeFull(log.timestamp),
                        Icons.access_time_rounded),
                    const SizedBox(height: 16),

                    // Message content
                    Text(
                      'Contenu du message',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          log.messageContent,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Retry button if failed
                    if (log.smsStatus == SmsStatus.failed)
                      SizedBox(
                        width: double.infinity,
                        child: GradientBorderButton(
                          text: 'Renvoyer le SMS',
                          icon: Icons.refresh_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeFull(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${_formatTime(time)}';
  }
}
