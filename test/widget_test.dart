import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aifin/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AiFinApp());

    // Expect to find at least one widget (i.e. app didn't crash)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
