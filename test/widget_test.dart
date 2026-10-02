import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:integration/app.dart';
import 'package:integration/theme/theme.dart';
import 'package:integration/widgets/common/fields.dart';

void main() {
  testWidgets('builder shell renders the default actions section', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: AppMakerApp()));
    await tester.pumpAndSettle();

    expect(find.text('AppMaker'), findsOneWidget);
    expect(find.text('Action flows'), findsOneWidget);
  });

  testWidgets('every builder section lays out without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: AppMakerApp()));
    await tester.pumpAndSettle();

    for (final section in const [
      'Variables',
      'APIs',
      'Mapping',
      'Bindings',
      'Actions',
    ]) {
      await tester.tap(find.text(section).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('mapping select and run button share the same height', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: AppMakerApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapping').first);
    await tester.pumpAndSettle();

    final button = tester.getSize(
      find.byKey(const ValueKey('mappingRunButton')),
    );
    final dropdown = tester.getSize(find.byType(AppDropdown<String>).first);

    expect(button.height, AppSpacing.control);
    expect(dropdown.height, AppSpacing.control);
  });
}
