import 'package:flutter_test/flutter_test.dart';
import 'package:sms_sender/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmsSenderApp());
    expect(find.text('لوحة التحكم'), findsOneWidget);
  });
}
