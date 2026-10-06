import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point for the foreground service — must be top-level
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SmsTaskHandler());
}

/// Task handler that keeps the app process alive
class SmsTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('🟢 Foreground task started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Keep-alive heartbeat — the real work is done by the Supabase listener
    debugPrint('💓 Foreground task heartbeat');
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('🔴 Foreground task destroyed');
  }
}
