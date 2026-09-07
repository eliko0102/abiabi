// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_business_agent/main.dart';

void main() {
  testWidgets('does not offer guest access and shows the auth form', (tester) async {
    await tester.pumpWidget(const AiBusinessAgentApp());
    await tester.pumpAndSettle();

    expect(find.text('Qonaq kimi davam et'), findsNothing);
    await tester.tap(find.text('Qeydiyyat'));
    await tester.pumpAndSettle();

    expect(find.text('Ad və soyad'), findsOneWidget);
    expect(find.text('Telefon'), findsOneWidget);
    expect(find.text('Doğum tarixi'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
  });
}
