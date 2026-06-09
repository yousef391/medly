import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  late List<SmsTemplate> _templates;

  @override
  void initState() {
    super.initState();
    _templates = List.from(MockData.templates);
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
                  'Modèles SMS',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérez les modèles de messages automatiques',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Info card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildInfoCard(context),
          ),
        ),

        // Templates list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildTemplateCard(context, _templates[index]);
              },
              childCount: _templates.length,
            ),
          ),
        ),

        // Add template button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: _buildAddTemplateButton(context),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Variables disponibles',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildVariableChip('{name}'),
                    _buildVariableChip('{phone}'),
                    _buildVariableChip('{tracking}'),
                    _buildVariableChip('{wilaya}'),
                    _buildVariableChip('{price}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, SmsTemplate template) {
    Color eventColor;
    IconData eventIcon;
    switch (template.eventType) {
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
        eventIcon = Icons.sms_outlined;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(eventIcon, color: eventColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 2),
                    StatusBadge(
                      label: template.eventType == WebhookEventType.atWilaya
                          ? 'À votre wilaya'
                          : 'Sorti à livraison',
                      color: eventColor,
                    ),
                  ],
                ),
              ),
              // Active toggle
              Switch(
                value: template.isActive,
                onChanged: (val) {
                  setState(() {
                    final idx = _templates.indexOf(template);
                    _templates[idx] = template.copyWith(isActive: val);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Message preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                template.messageTemplate,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                'Modifier',
                Icons.edit_outlined,
                AppColors.primary,
                () => _showEditTemplateSheet(context, template),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                'Tester',
                Icons.send_outlined,
                AppColors.accentGreen,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTemplateButton(BuildContext context) {
    return GlassCard(
      onTap: () => _showEditTemplateSheet(context, null),
      borderColor: AppColors.primary.withValues(alpha: 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            'Ajouter un modèle',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTemplateSheet(BuildContext context, SmsTemplate? template) {
    final isNew = template == null;
    final nameController = TextEditingController(text: template?.name ?? '');
    final messageController =
        TextEditingController(text: template?.messageTemplate ?? '');
    WebhookEventType selectedEvent =
        template?.eventType ?? WebhookEventType.atWilaya;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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

                  Text(
                    isNew ? 'Nouveau modèle' : 'Modifier le modèle',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),

                  // Template name
                  Text(
                    'Nom du modèle',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Ex: Message arrivée wilaya',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Event type
                  Text(
                    'Événement déclencheur',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEventOption(
                          'À votre wilaya',
                          Icons.location_on_outlined,
                          AppColors.statusAtWilaya,
                          selectedEvent == WebhookEventType.atWilaya,
                          () => setSheetState(() =>
                              selectedEvent = WebhookEventType.atWilaya),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildEventOption(
                          'Sorti à livraison',
                          Icons.local_shipping_outlined,
                          AppColors.statusOutDelivery,
                          selectedEvent == WebhookEventType.outForDelivery,
                          () => setSheetState(() =>
                              selectedEvent = WebhookEventType.outForDelivery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Message template
                  Text(
                    'Message (arabe)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'اكتب الرسالة هنا...',
                      hintTextDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: GradientBorderButton(
                      text: isNew ? 'Créer le modèle' : 'Enregistrer',
                      icon: Icons.save_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventOption(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? color : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
