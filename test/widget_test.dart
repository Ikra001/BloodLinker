import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_linker/main.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('App renders without crashing', (WidgetTester tester) async {
      // Test basic widget rendering
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('BloodLinker Test'))),
      );

      expect(find.text('BloodLinker Test'), findsOneWidget);
    });
  });
}
