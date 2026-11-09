import 'package:astro_log/gallary_tile.dart';
import 'package:astro_log/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('observation details and notes scroll on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await S.load(const Locale('en'));
    await initializeDateFormatting();

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: GallaryTile(
            'Observation',
            time: DateTime(2024, 9, 22, 21),
            messier: 31,
            ngc: 224,
            latitude: 40,
            longitude: -74,
            location:
                'A long observing location that wraps across multiple lines',
            notes: ['A note at the end of the observation'],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Observation'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('A note at the end of the observation'),
      200,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('A note at the end of the observation'), findsOneWidget);
    expect(find.text(S.current.closeDetails), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
