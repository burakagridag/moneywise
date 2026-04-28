// Smoke test — verifies the app widget tree renders without crashing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moneywise/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyWiseApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
