// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_business_agent/main.dart';

void main() {
  testWidgets('opens the dashboard after guest access', (tester) async {
    await tester.pumpWidget(const AiBusinessAgentApp());

    final guestButton = find.text('Qonaq kimi davam et');
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    expect(find.text('AI Business Agent'), findsWidgets);
    expect(find.text('EAI Analytics'), findsOneWidget);
    expect(find.textContaining('Köhnə nöqtəni'), findsOneWidget);
    expect(find.textContaining('Yeni nöqtə'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
  });
}
