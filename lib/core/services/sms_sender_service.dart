import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Algerian mobile operator
enum AlgerianOperator {
  mobilis,  // 06xx
  djezzy,   // 07xx
  ooredoo,  // 05xx
  unknown,
}

/// Represents a SIM card on the device
class SimCard {
  final int subscriptionId;
  final int simSlot;
  final String carrierName;
  final String displayName;
  final String number;

  const SimCard({
    required this.subscriptionId,
    required this.simSlot,
    required this.carrierName,
    required this.displayName,
    required this.number,
  });

  factory SimCard.fromMap(Map<dynamic, dynamic> map) {
    return SimCard(
      subscriptionId: map['subscriptionId'] as int,
      simSlot: map['simSlot'] as int,
      carrierName: map['carrierName'] as String? ?? 'SIM',
      displayName: map['displayName'] as String? ?? 'SIM',
      number: map['number'] as String? ?? '',
    );
  }

  String get label => '$displayName (SIM ${simSlot + 1})';

  /// Detect which operator this SIM belongs to
  AlgerianOperator get operator {
    final name = carrierName.toLowerCase();
    if (name.contains('mobilis')) return AlgerianOperator.mobilis;
    if (name.contains('djezzy') || name.contains('orascom') || name.contains('otr')) return AlgerianOperator.djezzy;
    if (name.contains('ooredoo') || name.contains('nedjma')) return AlgerianOperator.ooredoo;
    return AlgerianOperator.unknown;
  }
}

/// SIM selection mode
enum SimSelectionMode {
  auto,     // Match SIM to customer's operator
  manual,   // Always use selected SIM
}

/// Service for sending SMS via the device's SIM card
class SmsSenderService {
  static const _channel = MethodChannel('com.ecom.sms_sender/sms');

  /// Current SIM selection mode
  static SimSelectionMode selectionMode = SimSelectionMode.auto;

  /// Manually selected SIM subscription ID (-1 = default)
  static int selectedSubscriptionId = -1;

  /// Cached SIM cards
  static List<SimCard> _cachedSims = [];

  /// Detect operator from phone number prefix
  static AlgerianOperator detectOperator(String phone) {
    // Normalize: remove spaces, +213, etc.
    String normalized = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (normalized.startsWith('213')) normalized = '0${normalized.substring(3)}';
    if (normalized.startsWith('+213')) normalized = '0${normalized.substring(4)}';

    if (normalized.length < 4) return AlgerianOperator.unknown;

    final prefix = normalized.substring(0, 2);
    switch (prefix) {
      case '06':
        return AlgerianOperator.mobilis;
      case '07':
        return AlgerianOperator.djezzy;
      case '05':
        return AlgerianOperator.ooredoo;
      default:
        return AlgerianOperator.unknown;
    }
  }

  /// Find the best SIM for a given phone number
  static int _getSubscriptionIdForPhone(String phone) {
    if (selectionMode == SimSelectionMode.manual) {
      return selectedSubscriptionId;
    }

    // Auto mode: match operator
    final targetOperator = detectOperator(phone);
    if (targetOperator == AlgerianOperator.unknown) {
      return selectedSubscriptionId; // fallback to default/selected
    }

    // Find a SIM that matches the operator
    for (final sim in _cachedSims) {
      if (sim.operator == targetOperator) {
        debugPrint('🔄 Auto SIM: ${sim.carrierName} for ${targetOperator.name}');
        return sim.subscriptionId;
      }
    }

    // No matching SIM found, use default
    debugPrint('⚠️ No SIM for ${targetOperator.name}, using default');
    return selectedSubscriptionId;
  }

  /// Send an SMS message via the best matching SIM
  static Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    // Ensure SIMs are cached
    if (_cachedSims.isEmpty) {
      _cachedSims = await getSimCards();
    }

    final subId = _getSubscriptionIdForPhone(phone);

    try {
      final result = await _channel.invokeMethod('sendSms', {
        'phone': phone,
        'message': message,
        'subscriptionId': subId,
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('SMS send error: ${e.code} - ${e.message}');
      return false;
    }
  }

  /// Get list of available SIM cards
  static Future<List<SimCard>> getSimCards() async {
    try {
      final result = await _channel.invokeMethod('getSimCards');
      if (result is List) {
        _cachedSims = result
            .map((e) => SimCard.fromMap(e as Map<dynamic, dynamic>))
            .toList();
        return _cachedSims;
      }
      return [];
    } on PlatformException catch (e) {
      debugPrint('Get SIM cards error: ${e.code} - ${e.message}');
      return [];
    }
  }

  /// Check if SMS permission is granted
  static Future<bool> hasSmsPermission() async {
    try {
      final result = await _channel.invokeMethod('hasSmsPermission');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  /// Request SMS permission from the user
  static Future<bool> requestSmsPermission() async {
    try {
      final result = await _channel.invokeMethod('requestSmsPermission');
      return result == true;
    } on PlatformException {
      return false;
    }
  }
}
