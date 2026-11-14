import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:carebox/main.dart';
import 'package:carebox/providers/medication_provider.dart';

void main() {
  testWidgets('CareBox app loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CareBoxApp());
    expect(find.text('CareBox'), findsWidgets);
  });

  testWidgets('MainScaffold mounts IndexedStack with all screens', (WidgetTester tester) async {
    final provider = MedicationProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<MedicationProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: MainScaffold(),
        ),
      ),
    );

    // Verify IndexedStack exists with all screens
    final indexedStackFinder = find.byType(IndexedStack);
    expect(indexedStackFinder, findsOneWidget);

    final IndexedStack indexedStack = tester.widget(indexedStackFinder);
    expect(indexedStack.index, 0);
    expect(indexedStack.children.length, 4);

    // Tap Medications tab
    await tester.tap(find.text('Medications'));
    await tester.pumpAndSettle();

    final IndexedStack updatedStack = tester.widget(indexedStackFinder);
    expect(updatedStack.index, 1);

    // Tap Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    final IndexedStack settingsStack = tester.widget(indexedStackFinder);
    expect(settingsStack.index, 3);
  });
}
