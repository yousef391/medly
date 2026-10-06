import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/sms_sender_service.dart';
import '../../core/services/webhook_listener_service.dart';
import '../../core/services/foreground_task_handler.dart';
import '../../widgets/shared_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _webhookEnabled = WebhookListenerService.isListening;
  bool _autoSendSms = true;
  bool _notificationsEnabled = true;
  bool _retryFailed = true;
  final int _retryCount = 3;

  String get _webhookUrl {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'inconnu';
    return 'https://alrvuuoaqnbvkbwtizch.supabase.co/functions/v1/yalidine-webhook?user_id=$userId';
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paramètres',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Configuration du webhook et des SMS',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Webhook Configuration Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Configuration Webhook'),
                _buildWebhookStatusCard(context),
                const SizedBox(height: 12),
                _buildSettingCard(
                  context,
                  icon: Icons.link_rounded,
                  title: 'Votre URL Webhook',
                  subtitle: _webhookUrl,
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _webhookUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('URL copiée ! À coller dans Yalidine.'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // SMS Configuration Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Configuration SMS'),
                _buildSwitchCard(
                  context,
                  icon: Icons.send_rounded,
                  title: 'Envoi automatique',
                  subtitle: 'Envoyer les SMS automatiquement via la SIM',
                  value: _autoSendSms,
                  onChanged: (val) =>
                      setState(() => _autoSendSms = val),
                  color: AppColors.accentGreen,
                ),
                const SizedBox(height: 8),
                _buildSwitchCard(
                  context,
                  icon: Icons.refresh_rounded,
                  title: 'Réessayer automatiquement',
                  subtitle: 'Réessayer $_retryCount fois en cas d\'échec',
                  value: _retryFailed,
                  onChanged: (val) =>
                      setState(() => _retryFailed = val),
                  color: AppColors.accentOrange,
                ),
                const SizedBox(height: 8),
                _buildSwitchCard(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Recevoir les notifications de statut',
                  value: _notificationsEnabled,
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        ),

        // SIM Card Info Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Carte SIM'),
                _buildSimModeSelector(context),
                const SizedBox(height: 12),
                if (SmsSenderService.selectionMode == SimSelectionMode.auto)
                  _buildAutoModeInfo(context),
                if (SmsSenderService.selectionMode == SimSelectionMode.manual)
                  _buildSimCard(context),
              ],
            ),
          ),
        ),

        // Danger Zone
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Zone de danger'),
                _buildDangerCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleService(bool enable) async {
    setState(() => _webhookEnabled = enable);
    if (enable) {
      // Start the foreground service and listener
      WebhookListenerService.startListening();
      if (!await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.startService(
          serviceId: 256,
          notificationTitle: 'SMS Sender — En écoute',
          notificationText: 'Écoute les mises à jour Yalidine',
          callback: startCallback,
        );
      }
    } else {
      // Stop everything
      WebhookListenerService.stopListening();
      await FlutterForegroundTask.stopService();
    }
  }

  Widget _buildWebhookStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _webhookEnabled
            ? LinearGradient(
                colors: [
                  AppColors.accentGreen.withValues(alpha: 0.08),
                  AppColors.accentGreen.withValues(alpha: 0.02),
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.accentRed.withValues(alpha: 0.08),
                  AppColors.accentRed.withValues(alpha: 0.02),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (_webhookEnabled ? AppColors.accentGreen : AppColors.accentRed)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_webhookEnabled
                      ? AppColors.accentGreen
                      : AppColors.accentRed)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _webhookEnabled
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              color:
                  _webhookEnabled ? AppColors.accentGreen : AppColors.accentRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _webhookEnabled
                      ? 'Webhook Actif'
                      : 'Webhook Désactivé',
                  style: TextStyle(
                    color: _webhookEnabled
                        ? AppColors.accentGreen
                        : AppColors.accentRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _webhookEnabled
                      ? 'En écoute des webhooks Yalidine'
                      : 'Le serveur est arrêté',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _webhookEnabled,
            onChanged: (val) => _toggleService(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildSwitchCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildSimModeSelector(BuildContext context) {
    final isAuto = SmsSenderService.selectionMode == SimSelectionMode.auto;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() =>
                SmsSenderService.selectionMode = SimSelectionMode.auto),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isAuto
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAuto
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: isAuto ? AppColors.primary : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Auto',
                    style: TextStyle(
                      color: isAuto ? AppColors.primary : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() =>
                SmsSenderService.selectionMode = SimSelectionMode.manual),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !isAuto
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !isAuto
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.sim_card_outlined,
                    color: !isAuto ? AppColors.primary : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manuel',
                    style: TextStyle(
                      color: !isAuto ? AppColors.primary : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoModeInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: AppColors.accentGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                'Mode automatique activé',
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildOperatorRow('06xx', 'Mobilis', '→ SIM Mobilis'),
          const SizedBox(height: 6),
          _buildOperatorRow('07xx', 'Djezzy', '→ SIM Djezzy'),
          const SizedBox(height: 6),
          _buildOperatorRow('05xx', 'Ooredoo', '→ SIM Ooredoo'),
          const SizedBox(height: 10),
          Text(
            'Si aucune SIM ne correspond, la SIM par défaut est utilisée.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorRow(String prefix, String operator, String action) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            prefix,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          operator,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          action,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSimCard(BuildContext context) {
    return FutureBuilder<List<SimCard>>(
      future: SmsSenderService.getSimCards(),
      builder: (context, snapshot) {
        final sims = snapshot.data ?? [];

        if (sims.isEmpty) {
          return GlassCard(
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sim_card_alert_outlined,
                    color: AppColors.accentOrange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aucune carte SIM détectée',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Accordez la permission téléphone',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: sims.map((sim) {
            final isSelected =
                SmsSenderService.selectedSubscriptionId == sim.subscriptionId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    SmsSenderService.selectedSubscriptionId =
                        sim.subscriptionId;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? AppColors.primaryGradient
                              : null,
                          color: isSelected
                              ? null
                              : AppColors.textMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.sim_card_outlined,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SIM ${sim.simSlot + 1} — ${sim.carrierName}',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (sim.number.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                sim.number,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        )
                      else
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.textMuted.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDangerCard(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      borderColor: AppColors.accentRed.withValues(alpha: 0.15),
      child: Column(
        children: [
          _buildDangerAction(
            'Se déconnecter',
            'Fermer la session actuelle',
            Icons.logout_rounded,
            () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
          Divider(
            color: Colors.white.withValues(alpha: 0.04),
            height: 20,
          ),
          _buildDangerAction(
            'Effacer les logs',
            'Supprimer tout l\'historique des SMS',
            Icons.delete_outline_rounded,
            () {},
          ),
          Divider(
            color: Colors.white.withValues(alpha: 0.04),
            height: 20,
          ),
          _buildDangerAction(
            'Réinitialiser les paramètres',
            'Remettre tous les paramètres par défaut',
            Icons.restore_rounded,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDangerAction(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accentRed, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.accentRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textMuted,
            size: 14,
          ),
        ],
      ),
    );
  }

}
