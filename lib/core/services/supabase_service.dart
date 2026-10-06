import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  // ── Real-time stream of new unprocessed webhook events ──
  static Stream<List<WebhookEvent>> streamWebhookEvents() {
    return _client
        .from('sms_webhook_events')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => WebhookEvent.fromJson(r)).toList());
  }

  // ── Mark a webhook event as processed ──
  static Future<void> markEventProcessed(String eventId) async {
    await _client
        .from('sms_webhook_events')
        .update({'processed': true})
        .eq('id', eventId);
  }

  // ── Insert SMS log ──
  static Future<void> insertSmsLog({
    required String webhookEventId,
    required String customerName,
    required String phoneNumber,
    required String trackingId,
    required String eventType,
    required String smsStatus,
    required String messageContent,
    required String wilaya,
  }) async {
    await _client.from('sms_logs').insert({
      'user_id': _client.auth.currentUser!.id,
      'webhook_event_id': webhookEventId,
      'customer_name': customerName,
      'phone_number': phoneNumber,
      'tracking_id': trackingId,
      'event_type': eventType,
      'sms_status': smsStatus,
      'message_content': messageContent,
      'wilaya': wilaya,
    });
  }

  // ── Fetch SMS logs ──
  static Future<List<SmsLogEntry>> fetchSmsLogs({
    String? statusFilter,
    String? eventTypeFilter,
    String? searchQuery,
  }) async {
    var query = _client.from('sms_logs').select().eq('user_id', _client.auth.currentUser!.id);

    if (statusFilter != null) {
      query = query.eq('sms_status', statusFilter);
    }
    if (eventTypeFilter != null) {
      query = query.eq('event_type', eventTypeFilter);
    }

    final data = await query.order('created_at', ascending: false);

    var logs = (data as List).map((r) => SmsLogEntry.fromJson(r)).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      logs = logs
          .where((l) =>
              l.customerName.toLowerCase().contains(q) ||
              l.phoneNumber.contains(q) ||
              l.trackingId.toLowerCase().contains(q))
          .toList();
    }

    return logs;
  }

  // ── Dashboard stats ──
  static Future<DashboardStats> getDashboardStats() async {
    final allLogs = await _client.from('sms_logs').select('sms_status, created_at').eq('user_id', _client.auth.currentUser!.id);
    final allEvents = await _client.from('sms_webhook_events').select('created_at').eq('user_id', _client.auth.currentUser!.id);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    int sent = 0, failed = 0, pending = 0, todaySent = 0;
    for (final log in allLogs) {
      final status = log['sms_status'] as String;
      if (status == 'sent') {
        sent++;
        final createdAt = DateTime.parse(log['created_at']);
        if (createdAt.isAfter(todayStart)) todaySent++;
      } else if (status == 'failed') {
        failed++;
      } else if (status == 'pending') {
        pending++;
      }
    }

    int todayWebhooks = 0;
    for (final event in allEvents) {
      final createdAt = DateTime.parse(event['created_at']);
      if (createdAt.isAfter(todayStart)) todayWebhooks++;
    }

    return DashboardStats(
      totalSmsSent: sent,
      totalSmsFailed: failed,
      totalSmsPending: pending,
      totalWebhooksReceived: allEvents.length,
      todaySmsSent: todaySent,
      todayWebhooks: todayWebhooks,
    );
  }
}
