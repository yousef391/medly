import '../models/models.dart';

/// Provides mock data for UI development
class MockData {
  static DashboardStats get stats => const DashboardStats(
        totalSmsSent: 1247,
        totalSmsFailed: 23,
        totalSmsPending: 5,
        totalWebhooksReceived: 1380,
        todaySmsSent: 47,
        todayWebhooks: 52,
      );

  static List<SmsTemplate> get templates => const [
        SmsTemplate(
          id: '1',
          name: 'وصل الطرد للولاية',
          eventType: WebhookEventType.atWilaya,
          messageTemplate:
              'مرحبا {name}، طردك رقم {tracking} وصل لولاية {wilaya}. سيتصل بك المندوب قريبا. يرجى تحضير المبلغ {price} دج. شكرا لثقتك.',
          isActive: true,
        ),
        SmsTemplate(
          id: '2',
          name: 'خرج للتسليم',
          eventType: WebhookEventType.outForDelivery,
          messageTemplate:
              'مرحبا {name}، طردك رقم {tracking} خرج للتسليم اليوم. يرجى البقاء متاحا على الرقم {phone}. المبلغ المطلوب {price} دج.',
          isActive: true,
        ),
      ];

  static List<SmsLogEntry> get recentLogs => [
        SmsLogEntry(
          id: '1',
          customerName: 'أحمد بن علي',
          phoneNumber: '0555123456',
          trackingId: 'YAL-2025-00847',
          eventType: WebhookEventType.atWilaya,
          smsStatus: SmsStatus.sent,
          messageContent: 'مرحبا أحمد، طردك وصل لولاية الجزائر.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          wilaya: 'الجزائر',
        ),
        SmsLogEntry(
          id: '2',
          customerName: 'فاطمة زهراء',
          phoneNumber: '0661987654',
          trackingId: 'YAL-2025-00848',
          eventType: WebhookEventType.outForDelivery,
          smsStatus: SmsStatus.sent,
          messageContent: 'مرحبا فاطمة، طردك خرج للتسليم اليوم.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
          wilaya: 'وهران',
        ),
        SmsLogEntry(
          id: '3',
          customerName: 'كريم مصطفى',
          phoneNumber: '0770456789',
          trackingId: 'YAL-2025-00849',
          eventType: WebhookEventType.atWilaya,
          smsStatus: SmsStatus.failed,
          messageContent: 'مرحبا كريم، طردك وصل لولاية قسنطينة.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          wilaya: 'قسنطينة',
        ),
        SmsLogEntry(
          id: '4',
          customerName: 'سارة بوزيد',
          phoneNumber: '0555678901',
          trackingId: 'YAL-2025-00850',
          eventType: WebhookEventType.outForDelivery,
          smsStatus: SmsStatus.pending,
          messageContent: 'مرحبا سارة، طردك خرج للتسليم اليوم.',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          wilaya: 'سطيف',
        ),
        SmsLogEntry(
          id: '5',
          customerName: 'ياسين حمادي',
          phoneNumber: '0661234567',
          trackingId: 'YAL-2025-00851',
          eventType: WebhookEventType.atWilaya,
          smsStatus: SmsStatus.sent,
          messageContent: 'مرحبا ياسين، طردك وصل لولاية البليدة.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          wilaya: 'البليدة',
        ),
        SmsLogEntry(
          id: '6',
          customerName: 'نور الدين',
          phoneNumber: '0770112233',
          trackingId: 'YAL-2025-00852',
          eventType: WebhookEventType.outForDelivery,
          smsStatus: SmsStatus.sent,
          messageContent: 'مرحبا نور الدين، طردك خرج للتسليم.',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          wilaya: 'تيزي وزو',
        ),
        SmsLogEntry(
          id: '7',
          customerName: 'لينا عبد الله',
          phoneNumber: '0555998877',
          trackingId: 'YAL-2025-00853',
          eventType: WebhookEventType.atWilaya,
          smsStatus: SmsStatus.sent,
          messageContent: 'مرحبا لينا، طردك وصل لولاية عنابة.',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          wilaya: 'عنابة',
        ),
      ];
}
