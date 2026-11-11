import 'package:flutter_test/flutter_test.dart';
import 'package:trekguard_ai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TrekGuardApp());
    expect(find.byType(TrekGuardApp), findsOneWidget);
  });
}
