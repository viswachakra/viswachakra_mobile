// Basic smoke test. The full app requires Supabase.initialize (network + keys),
// so we test a lightweight widget instead of pumping the whole app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a basic widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Viswachakra'))),
    );
    expect(find.text('Viswachakra'), findsOneWidget);
  });
}
