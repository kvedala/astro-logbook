import 'package:astro_log/list_of_objects.dart';
import 'package:astro_log/objects.dart';
import 'package:astro_log/models/ra_dec.dart';
import 'package:astro_log/services/tonight_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final north = Messier(
    31,
    'Galaxy',
    const RightAscession(0, 0),
    const Declination(90, 0, '+'),
    ngcNumbers: [224],
  );
  final south = Messier(
    2,
    'Cluster',
    const RightAscession(0, 0),
    const Declination(90, 0, '-'),
  );
  final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));

  testWidgets('tile and status icons have separate actions', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = 0;
    var observations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Column(
              children: [
                MessierListTile(
                  object: north,
                  viewed: true,
                  sky: sky,
                  onOpenObject: () => opened++,
                  onOpenObservations: () => observations++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Visible in darkness tonight'), findsNothing);
    await tester.tap(find.text('M 31 · Galaxy'));
    expect(opened, 1);
    await tester.tap(find.byTooltip('Open M 31 on Wikipedia'));
    expect(opened, 2);
    await tester.tap(find.byTooltip('Observed: View observations'));
    expect(observations, 1);
    expect(opened, 2);
    final link = tester.getCenter(find.byTooltip('Open M 31 on Wikipedia'));
    final status = tester.getCenter(
      find.byTooltip('Visibility details: Visible in darkness tonight'),
    );
    final observation = tester.getCenter(
      find.byTooltip('Observed: View observations'),
    );
    expect(link.dy, status.dy);
    expect(status.dy, observation.dy);
    expect(tester.getSize(find.byType(MessierListTile)).height, lessThan(120));
    await tester.tap(
      find.byTooltip('Visibility details: Visible in darkness tonight'),
    );
    await tester.pumpAndSettle();
    expect(find.text('M 31 visibility'), findsOneWidget);
    expect(find.textContaining('Best '), findsOneWidget);
    expect(opened, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden and unknown visibility are not presented as visible', (
    tester,
  ) async {
    var added = 0;
    Widget tile(TonightSky? currentSky) => MaterialApp(
      home: Scaffold(
        body: MessierListTile(
          object: south,
          viewed: false,
          sky: currentSky,
          onOpenObject: () {},
          onOpenObservations: () => added++,
        ),
      ),
    );
    await tester.pumpWidget(tile(sky));
    expect(
      find.byTooltip('Visibility details: Not visible in darkness tonight'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Not observed: Add observation'));
    expect(added, 1);

    await tester.pumpWidget(tile(null));
    expect(
      find.byTooltip('Visibility details: Visibility unavailable'),
      findsOneWidget,
    );
    await tester.tap(
      find.byTooltip('Visibility details: Visibility unavailable'),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Visibility unavailable'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      tile(TonightSky(78.2, 15.6, DateTime.utc(2024, 6, 21, 18))),
    );
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('Visibility details: No astronomical darkness tonight'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
