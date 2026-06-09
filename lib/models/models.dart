/// Represents a webhook event from Yalidine delivery service
enum WebhookEventType {
  atWilaya,       // Colis est à votre wilaya
  outForDelivery, // Sorti à livraison
  delivered,      // Livré
  returned,       // Retour
  unknown,
}

/// SMS sending status
enum SmsStatus {
  pending,
  sent,
  failed,
}

/// Represents a single SMS log entry
class SmsLogEntry {
  final String id;
  final String customerName;
  final String phoneNumber;
  final String trackingId;
  final WebhookEventType eventType;
  final SmsStatus smsStatus;
  final String messageContent;
  final DateTime timestamp;
  final String wilaya;

  const SmsLogEntry({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.trackingId,
    required this.eventType,
    required this.smsStatus,
    required this.messageContent,
    required this.timestamp,
    required this.wilaya,
  });

  String get eventTypeLabel {
    switch (eventType) {
      case WebhookEventType.atWilaya:
        return 'في الولاية';
      case WebhookEventType.outForDelivery:
        return 'خرج للتسليم';
      case WebhookEventType.delivered:
        return 'تم التسليم';
      case WebhookEventType.returned:
        return 'مرتجع';
      case WebhookEventType.unknown:
        return 'غير معروف';
    }
  }

  String get eventTypeLabelFr {
    switch (eventType) {
      case WebhookEventType.atWilaya:
        return 'À votre wilaya';
      case WebhookEventType.outForDelivery:
        return 'Sorti à livraison';
      case WebhookEventType.delivered:
        return 'Livré';
      case WebhookEventType.returned:
        return 'Retour';
      case WebhookEventType.unknown:
        return 'Inconnu';
    }
  }

  String get smsStatusLabel {
    switch (smsStatus) {
      case SmsStatus.pending:
        return 'En attente';
      case SmsStatus.sent:
        return 'Envoyé';
      case SmsStatus.failed:
        return 'Échoué';
    }
  }
}

/// Represents SMS message templates
class SmsTemplate {
  final String id;
  final String name;
  final WebhookEventType eventType;
  final String messageTemplate;
  final bool isActive;

  const SmsTemplate({
    required this.id,
    required this.name,
    required this.eventType,
    required this.messageTemplate,
    required this.isActive,
  });

  SmsTemplate copyWith({
    String? name,
    String? messageTemplate,
    bool? isActive,
  }) {
    return SmsTemplate(
      id: id,
      name: name ?? this.name,
      eventType: eventType,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Webhook configuration
class WebhookConfig {
  final String webhookUrl;
  final String apiToken;
  final bool isListening;
  final int port;

  const WebhookConfig({
    required this.webhookUrl,
    required this.apiToken,
    required this.isListening,
    this.port = 8080,
  });
}

/// Dashboard statistics
class DashboardStats {
  final int totalSmsSent;
  final int totalSmsFailed;
  final int totalSmsPending;
  final int totalWebhooksReceived;
  final int todaySmsSent;
  final int todayWebhooks;

  const DashboardStats({
    required this.totalSmsSent,
    required this.totalSmsFailed,
    required this.totalSmsPending,
    required this.totalWebhooksReceived,
    required this.todaySmsSent,
    required this.todayWebhooks,
  });
}
