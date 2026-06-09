import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _webhookEnabled = true;
  bool _autoSendSms = true;
  bool _notificationsEnabled = true;
  bool _retryFailed = true;
  final int _retryCount = 3;
  final int _port = 8080;
  final String _webhookUrl = 'https://your-server.com/webhook/yalidine';
  final String _apiToken = 'yal_tk_a7b3c9d2e1f4...';

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
                  title: 'URL du Webhook',
                  subtitle: _webhookUrl,
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _webhookUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('URL copiée !'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.key_rounded,
                  title: 'Token API Yalidine',
                  subtitle: _apiToken,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () => _showTokenEditDialog(context),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.router_outlined,
                  title: 'Port du serveur',
                  subtitle: 'Port: $_port',
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () {},
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
                      ? 'Écoute sur le port $_port'
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
            onChanged: (val) =>
                setState(() => _webhookEnabled = val),
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

  Widget _buildSimCard(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sim_card_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SIM active',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mobilis - 0555 XX XX XX',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusBadge(
                label: 'Connectée',
                color: AppColors.accentGreen,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildSimStat('SMS restants', '∞', AppColors.accentGreen),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                _buildSimStat("Envoyés aujourd'hui", '47', AppColors.accent),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                _buildSimStat('Réseau', '4G', AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerCard(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      borderColor: AppColors.accentRed.withValues(alpha: 0.15),
      child: Column(
        children: [
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

  void _showTokenEditDialog(BuildContext context) {
    final controller = TextEditingController(text: _apiToken);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Token API Yalidine',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez votre token API depuis le dashboard Yalidine',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  hintText: 'yal_tk_...',
                  prefixIcon: Icon(Icons.key_rounded, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GradientBorderButton(
                  text: 'Enregistrer',
                  icon: Icons.save_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
