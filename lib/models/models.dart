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

/// Maps Yalidine status strings to our event types
WebhookEventType mapEventType(String? eventType) {
  switch (eventType) {
    case 'atWilaya':
      return WebhookEventType.atWilaya;
    case 'outForDelivery':
      return WebhookEventType.outForDelivery;
    case 'delivered':
      return WebhookEventType.delivered;
    case 'returned':
      return WebhookEventType.returned;
    default:
      return WebhookEventType.unknown;
  }
}

/// Maps SmsStatus from string
SmsStatus mapSmsStatus(String? status) {
  switch (status) {
    case 'sent':
      return SmsStatus.sent;
    case 'failed':
      return SmsStatus.failed;
    default:
      return SmsStatus.pending;
  }
}

/// Raw webhook event from sms_webhook_events table
class WebhookEvent {
  final String id;
  final String? eventId;
  final String? eventType;
  final String tracking;
  final String? status;
  final String? reason;
  final String? customerName;
  final String? phoneNumber;
  final String? wilaya;
  final String? commune;
  final String? orderId;
  final bool processed;
  final DateTime? occurredAt;
  final DateTime createdAt;

  const WebhookEvent({
    required this.id,
    this.eventId,
    this.eventType,
    required this.tracking,
    this.status,
    this.reason,
    this.customerName,
    this.phoneNumber,
    this.wilaya,
    this.commune,
    this.orderId,
    this.processed = false,
    this.occurredAt,
    required this.createdAt,
  });

  factory WebhookEvent.fromJson(Map<String, dynamic> json) {
    return WebhookEvent(
      id: json['id'] as String,
      eventId: json['event_id'] as String?,
      eventType: json['event_type'] as String?,
      tracking: json['tracking'] as String,
      status: json['status'] as String?,
      reason: json['reason'] as String?,
      customerName: json['customer_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      wilaya: json['wilaya'] as String?,
      commune: json['commune'] as String?,
      orderId: json['order_id'] as String?,
      processed: json['processed'] as bool? ?? false,
      occurredAt: json['occurred_at'] != null
          ? DateTime.parse(json['occurred_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  WebhookEventType get mappedEventType => mapEventType(eventType);
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

  factory SmsLogEntry.fromJson(Map<String, dynamic> json) {
    return SmsLogEntry(
      id: json['id'] as String,
      customerName: json['customer_name'] as String? ?? 'Inconnu',
      phoneNumber: json['phone_number'] as String? ?? '',
      trackingId: json['tracking_id'] as String? ?? '',
      eventType: mapEventType(json['event_type'] as String?),
      smsStatus: mapSmsStatus(json['sms_status'] as String?),
      messageContent: json['message_content'] as String? ?? '',
      timestamp: DateTime.parse(json['created_at']),
      wilaya: json['wilaya'] as String? ?? '',
    );
  }

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

/// Hardcoded SMS message templates
class SmsTemplates {
  static const Map<WebhookEventType, String> templates = {
    WebhookEventType.outForDelivery:
        'مرحبا {name}، طردك خرج للتسليم اليوم. يرجى تحضير المبلغ وإبقاء هاتفك مفتوحا، سيتصل بك السائق اليوم. رقم التتبع: {tracking}',
    WebhookEventType.atWilaya:
        'مرحبا {name}، طردك وصل للولاية. سنتصل بك قريبا. رقم التتبع: {tracking}',
    WebhookEventType.delivered:
        'مرحبا {name}، تم تسليم طردك بنجاح. شكرا لثقتك! إذا واجهت أي مشكلة تواصل معنا واترك تعليق إيجابي على صفحتنا للحصول على تخفيض في طلبك القادم. رقم التتبع: {tracking}',
  };

  static const Map<WebhookEventType, String> templateNames = {
    WebhookEventType.outForDelivery: 'Sorti en livraison',
    WebhookEventType.atWilaya: 'Au centre (Wilaya)',
    WebhookEventType.delivered: 'Livré',
  };

  /// Returns the SMS message for a given event type with placeholders filled
  static String? buildMessage({
    required WebhookEventType eventType,
    required String customerName,
    required String tracking,
  }) {
    final template = templates[eventType];
    if (template == null) return null; // No SMS for returned/unknown

    return template
        .replaceAll('{name}', customerName)
        .replaceAll('{tracking}', tracking);
  }

  /// Whether this event type should trigger an SMS
  static bool shouldSendSms(WebhookEventType eventType) {
    return templates.containsKey(eventType);
  }
}

/// Webhook configuration
class WebhookConfig {
  final String webhookUrl;
  final String apiToken;
  final bool isListening;

  const WebhookConfig({
    required this.webhookUrl,
    required this.apiToken,
    required this.isListening,
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
