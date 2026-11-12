import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget pump smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('TrekGuard AI'),
          ),
        ),
      ),
    );

    expect(find.text('TrekGuard AI'), findsOneWidget);
  });
}
