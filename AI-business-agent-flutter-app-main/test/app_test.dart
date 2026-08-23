import 'package:flutter_test/flutter_test.dart';
import 'package:ai_business_agent/main.dart';

void main() {
  testWidgets('shows the authentication onboarding', (tester) async {
    await tester.pumpWidget(const AiBusinessAgentApp());

    expect(find.text('AI Business Agent'), findsWidgets);
    expect(find.text('Qeydiyyat'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Qonaq kimi davam et'), findsNothing);
  });
}
