import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import 'sms_sender_service.dart';
import 'supabase_service.dart';

/// Listens to new webhook events in real-time and auto-sends SMS
class WebhookListenerService {
  static StreamSubscription? _subscription;
  static bool _isListening = false;
  static final Set<String> _processedIds = {};

  /// Whether the listener is currently active
  static bool get isListening => _isListening;

  /// Callback for UI updates when a new event is processed
  static VoidCallback? onEventProcessed;

  static int _retryCount = 0;
  static Timer? _retryTimer;

  /// Start listening for new unprocessed webhook events
  static void startListening() {
    if (_isListening) return;
    _isListening = true;
    _retryCount = 0;

    debugPrint('🟢 WebhookListener: Starting real-time listener...');
    _connect();
  }

  static void _connect() {
    _subscription?.cancel();
    _subscription = Supabase.instance.client
        .from('sms_webhook_events')
        .stream(primaryKey: ['id'])
        .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .listen((rows) async {
      _retryCount = 0; // reset on successful connection
      for (final row in rows) {
        final event = WebhookEvent.fromJson(row);

        // Client-side filter: skip if already processed
        if (event.processed) continue;

        // Skip if already processed in this session
        if (_processedIds.contains(event.id)) continue;
        _processedIds.add(event.id);

        // Skip if no phone number
        if (event.phoneNumber == null || event.phoneNumber!.isEmpty) {
          debugPrint('⚠️ No phone for tracking ${event.tracking}, skipping');
          await SupabaseService.markEventProcessed(event.id);
          continue;
        }

        // Skip if event type doesn't need SMS (e.g. returned, unknown)
        if (!SmsTemplates.shouldSendSms(event.mappedEventType)) {
          debugPrint('⏭️ No SMS template for ${event.eventType}, skipping');
          await SupabaseService.markEventProcessed(event.id);
          continue;
        }

        // Build the SMS message from template
        final message = SmsTemplates.buildMessage(
          eventType: event.mappedEventType,
          customerName: event.customerName ?? 'العميل',
          tracking: event.tracking,
        );

        if (message == null) {
          await SupabaseService.markEventProcessed(event.id);
          continue;
        }

        debugPrint('📱 Sending SMS to ${event.phoneNumber}: ${event.mappedEventType}');

        // Send SMS via device SIM
        final success = await SmsSenderService.sendSms(
          phone: event.phoneNumber!,
          message: message,
        );

        // Log the result
        await SupabaseService.insertSmsLog(
          webhookEventId: event.id,
          customerName: event.customerName ?? 'Inconnu',
          phoneNumber: event.phoneNumber!,
          trackingId: event.tracking,
          eventType: event.eventType ?? 'unknown',
          smsStatus: success ? 'sent' : 'failed',
          messageContent: message,
          wilaya: event.wilaya ?? '',
        );

        // Mark the event as processed
        await SupabaseService.markEventProcessed(event.id);

        debugPrint(success
            ? '✅ SMS sent to ${event.phoneNumber}'
            : '❌ SMS failed to ${event.phoneNumber}');

        // Notify UI
        onEventProcessed?.call();
      }
    }, onError: (error) {
      debugPrint('❌ WebhookListener error: $error');
      _scheduleReconnect();
    });
  }

  /// Auto-reconnect with exponential backoff
  static void _scheduleReconnect() {
    if (!_isListening) return;

    _retryCount++;
    // Backoff: 5s, 10s, 20s, 40s, max 60s
    final delay = Duration(
      seconds: (_retryCount * 5).clamp(5, 60),
    );

    debugPrint('🔄 Reconnecting in ${delay.inSeconds}s (attempt $_retryCount)...');

    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (_isListening) {
        debugPrint('🔄 Attempting reconnect...');
        _connect();
      }
    });
  }

  /// Stop listening
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _isListening = false;
    _processedIds.clear();
    _retryCount = 0;
    debugPrint('🔴 WebhookListener: Stopped');
  }

  /// Process a single event manually (for retry)
  static Future<bool> processEvent(WebhookEvent event) async {
    if (event.phoneNumber == null || event.phoneNumber!.isEmpty) return false;

    final message = SmsTemplates.buildMessage(
      eventType: event.mappedEventType,
      customerName: event.customerName ?? 'العميل',
      tracking: event.tracking,
    );

    if (message == null) return false;

    final success = await SmsSenderService.sendSms(
      phone: event.phoneNumber!,
      message: message,
    );

    await SupabaseService.insertSmsLog(
      webhookEventId: event.id,
      customerName: event.customerName ?? 'Inconnu',
      phoneNumber: event.phoneNumber!,
      trackingId: event.tracking,
      eventType: event.eventType ?? 'unknown',
      smsStatus: success ? 'sent' : 'failed',
      messageContent: message,
      wilaya: event.wilaya ?? '',
    );

    if (success) {
      await SupabaseService.markEventProcessed(event.id);
    }

    onEventProcessed?.call();
    return success;
  }
}
