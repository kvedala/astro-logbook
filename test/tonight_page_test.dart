import 'dart:async';

import 'package:astro_log/object_tile.dart';
import 'package:astro_log/observation_actions.dart';
import 'package:astro_log/ra_dec.dart';
import 'package:astro_log/services/tonight_service.dart';
import 'package:astro_log/tonight_page.dart';
import 'package:location/location.dart' as gps;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const visible = ObservingTarget(
    31,
    'Spiral Galaxy',
    'Andromeda',
    3.4,
    RightAscession(0, 42.7),
    Declination(41, 16, '+'),
    [224],
  );
  const hidden = ObservingTarget(
    2,
    'Galaxy',
    null,
    null,
    RightAscession(0, 0),
    Declination(90, 0, '-'),
  );

  test('recognizes catalog checklist IDs even if metadata was lost', () {
    expect(isChecklistObjectDocumentId('catalog_messier_31'), isTrue);
    expect(isChecklistObjectDocumentId('catalog_ngc_31'), isTrue);
    expect(isChecklistObjectDocumentId('catalog_messier_bad'), isFalse);
    expect(isChecklistObjectDocumentId('custom-item'), isFalse);
  });

  test('matches NGC and Messier observations through catalog links', () {
    const ngc = ObservingTarget.ngc(
      99,
      'Galaxy',
      null,
      null,
      RightAscession(0, 0),
      Declination(90, 0, '+'),
      [77],
    );
    expect(
      targetWasViewed(visible, [
        {'ngc': 224},
      ]),
      isTrue,
    );
    expect(
      targetWasViewed(ngc, [
        {'messier': 77},
      ]),
      isTrue,
    );
    expect(
      targetWasViewed(ngc, [
        {'ngc': 99},
      ]),
      isTrue,
    );
    expect(
      targetWasViewed(ngc, [
        {'messier': 78},
        {'ngc': 98},
      ]),
      isFalse,
    );
  });

  testWidgets('tonight tiles update observation status and actions', (
    tester,
  ) async {
    const ngc = ObservingTarget.ngc(
      99,
      'Cluster',
      null,
      4,
      RightAscession(0, 0),
      Declination(90, 0, '+'),
      [77],
    );
    final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));
    final logs = ValueNotifier<List<Map<String, dynamic>>>([
      {'ngc': 224},
      {'messier': 77},
    ]);
    addTearDown(logs.dispose);
    ObservingTarget? selected;
    bool? observed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: logs,
            builder: (context, observations, _) => TonightResults(
              sky: sky,
              targets: [visible],
              observations: observations,
              ngcPageSource: () {
                var sent = false;
                return () async {
                  if (sent) return null;
                  sent = true;
                  return [ngc];
                };
              },
              onRefresh: () {},
              onOpenObject: (_) {},
              onOpenObservations: (target, viewed) {
                selected = target;
                observed = viewed;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Finder tile(String title) =>
        find.ancestor(of: find.text(title), matching: find.byType(ObjectTile));
    Finder action(String title, String label) =>
        find.descendant(of: tile(title), matching: find.byTooltip(label));
    await tester.scrollUntilVisible(find.text('M 31 · Spiral Galaxy'), 200);
    expect(
      action('M 31 · Spiral Galaxy', 'Observed: View observations'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('NGC 99 · Cluster'), 200);
    await tester.tap(action('NGC 99 · Cluster', 'Observed: View observations'));
    expect(selected?.number, 99);
    expect(selected?.isNgc, isTrue);
    expect(observed, isTrue);

    logs.value = [];
    await tester.pumpAndSettle();
    await tester.tap(
      action('NGC 99 · Cluster', 'Not observed: Add observation'),
    );
    expect(selected?.number, 99);
    expect(observed, isFalse);
    await tester.ensureVisible(find.text('M 31 · Spiral Galaxy'));
    expect(
      action('M 31 · Spiral Galaxy', 'Not observed: Add observation'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tonight objects can be added to and removed from the checklist',
    (tester) async {
      final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));
      final checklistIds = ValueNotifier<Set<String>>({});
      addTearDown(checklistIds.dispose);
      ObservingTarget? toggled;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<Set<String>>(
              valueListenable: checklistIds,
              builder: (context, ids, _) => TonightResults(
                sky: sky,
                targets: [visible],
                checklistObjectIds: ids,
                ngcPageSource: () =>
                    () async => null,
                onRefresh: () {},
                onOpenObject: (_) {},
                onToggleChecklist: (target) {
                  toggled = target;
                  final id = checklistObjectDocumentId(target);
                  final updated = {...ids};
                  if (!updated.add(id)) updated.remove(id);
                  checklistIds.value = updated;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('M 31 · Spiral Galaxy'));
      await tester.tap(find.byTooltip('Add to viewing checklist'));
      await tester.pumpAndSettle();
      expect(toggled, same(visible));
      expect(find.byTooltip('Remove from viewing checklist'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove from viewing checklist'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Add to viewing checklist'), findsOneWidget);
      expect(
        checklistObjectDocumentId(
          const ObservingTarget.ngc(
            31,
            'Galaxy',
            null,
            null,
            RightAscession(0, 0),
            Declination(0, 0, '+'),
          ),
        ),
        'catalog_ngc_31',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('observation stream updates status and reports errors', (
    tester,
  ) async {
    final logs = StreamController<List<Map<String, dynamic>>>();
    var requests = 0;
    addTearDown(logs.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightPage(
            locationProvider: () async => gps.LocationData.fromMap({
              'latitude': 40.0,
              'longitude': -74.0,
            }),
            catalogProvider: () => Stream.value([visible]),
            checklistProvider: () => Stream.value(<String>{}),
            observationsProvider: () => requests++ == 0
                ? logs.stream
                : Stream.value([
                    {'ngc': 224},
                  ]),
            ngcPageSource: () =>
                () async => null,
            clock: () => DateTime.utc(2024, 9, 22, 18),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(find.text('M 31 · Spiral Galaxy'), 200);
    expect(
      find.byTooltip('Observation status loading or unavailable'),
      findsOneWidget,
    );
    logs.add([]);
    await tester.pump();
    expect(find.byTooltip('Not observed: Add observation'), findsOneWidget);
    logs.add([
      {'ngc': 224},
    ]);
    await tester.pump();
    expect(find.byTooltip('Observed: View observations'), findsOneWidget);
    logs.addError(StateError('offline'));
    await tester.pump();
    expect(
      find.byTooltip('Observation status loading or unavailable'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('What’s visible tonight?'));
    expect(
      find.textContaining('Could not load observations: Bad state: offline'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry observations'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.text('M 31 · Spiral Galaxy'));
    expect(find.byTooltip('Observed: View observations'), findsOneWidget);
    expect(requests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checklist stream errors are shown and can be retried', (
    tester,
  ) async {
    final checklist = StreamController<Set<String>>();
    var requests = 0;
    addTearDown(checklist.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightPage(
            locationProvider: () async => gps.LocationData.fromMap({
              'latitude': 40.0,
              'longitude': -74.0,
            }),
            catalogProvider: () => Stream.value([visible]),
            observationsProvider: () => Stream.value([]),
            checklistProvider: () => requests++ == 0
                ? checklist.stream
                : Stream.value({'catalog_messier_31'}),
            ngcPageSource: () =>
                () async => null,
            clock: () => DateTime.utc(2024, 9, 22, 18),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    checklist.addError(StateError('offline'));
    await tester.pump();
    await tester.ensureVisible(find.text('What’s visible tonight?'));
    expect(
      find.textContaining('Could not load checklist: Bad state: offline'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry checklist'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.text('M 31 · Spiral Galaxy'));
    expect(find.byTooltip('Remove from viewing checklist'), findsOneWidget);
    expect(requests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a recent last-known location until a fresh fix arrives', (
    tester,
  ) async {
    final now = DateTime.utc(2024, 9, 22, 18);
    final fresh = Completer<gps.LocationData>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightPage(
            observationsProvider: () => Stream.value([]),
            checklistProvider: () => Stream.value(<String>{}),
            locationProvider: () => fresh.future,
            lastKnownLocationProvider: () async => gps.LocationData.fromMap({
              'latitude': 40.0,
              'longitude': -74.0,
              'time': now
                  .subtract(const Duration(minutes: 2))
                  .millisecondsSinceEpoch
                  .toDouble(),
            }),
            catalogProvider: () => Stream.value([visible]),
            ngcPageSource: () =>
                () async => null,
            clock: () => now,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.textContaining('Using a recent location while updating GPS'),
      findsOneWidget,
    );
    expect(
      tester.widget<TonightResults>(find.byType(TonightResults)).sky.latitude,
      40,
    );
    fresh.complete(
      gps.LocationData.fromMap({'latitude': 41.0, 'longitude': -73.0}),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.textContaining('Using a recent location while updating GPS'),
      findsNothing,
    );
    expect(
      tester.widget<TonightResults>(find.byType(TonightResults)).sky.latitude,
      41,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ignores a stale cached location and surfaces a fresh fix failure',
    (tester) async {
      final now = DateTime.utc(2024, 9, 22, 18);
      final fresh = Completer<gps.LocationData>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TonightPage(
              observationsProvider: () => Stream.value([]),
              checklistProvider: () => Stream.value(<String>{}),
              locationProvider: () => fresh.future,
              lastKnownLocationProvider: () async => gps.LocationData.fromMap({
                'latitude': 40.0,
                'longitude': -74.0,
                'time': now
                    .subtract(const Duration(minutes: 11))
                    .millisecondsSinceEpoch
                    .toDouble(),
              }),
              catalogProvider: () => Stream.value([visible]),
              ngcPageSource: () =>
                  () async => null,
              clock: () => now,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Getting location...'), findsOneWidget);
      expect(find.text('What’s visible tonight?'), findsNothing);
      fresh.completeError(StateError('GPS unavailable'));
      await tester.pump();
      expect(
        find.textContaining(
          'Could not get location: Bad state: GPS unavailable',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('starts loading the catalog while location is pending', (
    tester,
  ) async {
    final location = Completer<gps.LocationData>();
    var subscribed = false;
    final catalog = StreamController<List<ObservingTarget>>(
      onListen: () => subscribed = true,
    );
    addTearDown(catalog.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightPage(
            observationsProvider: () => Stream.value([]),
            checklistProvider: () => Stream.value(<String>{}),
            locationProvider: () => location.future,
            catalogProvider: () => catalog.stream,
            ngcPageSource: () =>
                () async => null,
            clock: () => DateTime.utc(2024, 9, 22, 18),
          ),
        ),
      ),
    );
    expect(subscribed, isTrue);
    expect(find.text('Getting location...'), findsOneWidget);
    catalog.add([visible]);
    await tester.pump();
    location.complete(
      gps.LocationData.fromMap({'latitude': 40.7128, 'longitude': -74.006}),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('What’s visible tonight?'), findsOneWidget);
    expect(find.text('Loading catalog...'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows sky events while the catalog is still loading', (
    tester,
  ) async {
    final catalog = StreamController<List<ObservingTarget>>();
    addTearDown(catalog.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightPage(
            observationsProvider: () => Stream.value([]),
            checklistProvider: () => Stream.value(<String>{}),
            locationProvider: () async => gps.LocationData.fromMap({
              'latitude': 40.7128,
              'longitude': -74.006,
            }),
            catalogProvider: () => catalog.stream,
            ngcPageSource: () =>
                () async => null,
            clock: () => DateTime.utc(2024, 9, 22, 18),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('What’s visible tonight?'), findsOneWidget);
    expect(find.textContaining('Sunset: Sun 22:52'), findsOneWidget);
    expect(find.text('Loading catalog...'), findsOneWidget);
    catalog.add([visible]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Loading catalog...'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retries location errors and loads the catalog', (tester) async {
    var requests = 0;
    final location = gps.LocationData.fromMap({
      'latitude': 40.7128,
      'longitude': -74.006,
    });
    final loading = Completer<gps.LocationData>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightPage(
            observationsProvider: () => Stream.value([]),
            checklistProvider: () => Stream.value(<String>{}),
            ngcPageSource: () =>
                () async => null,
            locationProvider: () {
              requests++;
              return requests == 1
                  ? Future<gps.LocationData>.error(Exception('GPS denied'))
                  : loading.future;
            },
            catalogProvider: () => Stream.value([visible]),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.textContaining('Could not get location: Exception: GPS denied'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    loading.complete(location);
    await tester.pump();
    await tester.pump();
    expect(find.text('What’s visible tonight?'), findsOneWidget);
    expect(requests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports catalog loading errors', (tester) async {
    final location = gps.LocationData.fromMap({
      'latitude': 40.7128,
      'longitude': -74.006,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightPage(
            observationsProvider: () => Stream.value([]),
            checklistProvider: () => Stream.value(<String>{}),
            ngcPageSource: () =>
                () async => null,
            locationProvider: () async => location,
            catalogProvider: () => Stream<List<ObservingTarget>>.error(
              StateError('catalog unavailable'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.textContaining('Could not load Messier catalog:'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows tonight’s events and visible object details', (
    tester,
  ) async {
    final sky = TonightSky(40.7128, -74.006, DateTime.utc(2024, 9, 22, 18));
    var refreshed = false;
    int? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightResults(
            ngcPageSource: () =>
                () async => null,
            sky: sky,
            targets: [visible, hidden],
            onRefresh: () => refreshed = true,
            onOpenObject: (target) => opened = target.number,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What’s visible tonight?'), findsOneWidget);
    expect(find.textContaining('Sunset: Sun 22:52'), findsOneWidget);
    expect(find.textContaining('Sunrise: Mon 10:45'), findsOneWidget);
    expect(find.textContaining('Astronomical darkness:'), findsOneWidget);
    expect(find.textContaining('Moonrise:'), findsOneWidget);
    expect(find.textContaining('Moonset:'), findsOneWidget);
    expect(find.text('Visible Messier and NGC objects'), findsOneWidget);

    await tester.tap(find.byTooltip('Refresh location and times'));
    expect(refreshed, isTrue);
    await tester.ensureVisible(find.text('M 31 · Spiral Galaxy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Andromeda · Magnitude 3.4'), findsOneWidget);
    expect(find.textContaining('Visible in darkness:'), findsNothing);
    await tester.tap(
      find.byTooltip('Visibility details: Visible in darkness tonight'),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Visible in darkness: Mon 00:23–Mon 09:13'),
      findsOneWidget,
    );
    expect(find.textContaining('Best Mon 05:28'), findsOneWidget);
    expect(find.text('M 2 · Galaxy'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('M 31 · Spiral Galaxy'));
    expect(opened, 31);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows full NGC constellation and explains visibility', (
    tester,
  ) async {
    final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightResults(
            sky: sky,
            targets: const [],
            ngcPageSource: () {
              var sent = false;
              return () async {
                if (sent) return null;
                sent = true;
                return const [
                  ObservingTarget.ngc(
                    1,
                    'Galaxy',
                    'Pegasus',
                    13,
                    RightAscession(0, 7.3),
                    Declination(27, 43, '+'),
                  ),
                ];
              };
            },
            onRefresh: () {},
            onOpenObject: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('About visibility'), findsOneWidget);
    await tester.tap(find.text('About visibility'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Visible times are when an object'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('NGC 1 · Galaxy'), 200);
    expect(find.textContaining('Pegasus · Magnitude 13'), findsOneWidget);
    await tester.tap(
      find.byTooltip('Visibility details: Visible in darkness tonight'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Visible in darkness:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only notes the Moon when it is up at the best time', (
    tester,
  ) async {
    final skies = List.generate(
      30,
      (day) => TonightSky(40.7128, -74.006, DateTime.utc(2024, 9, day + 1, 18)),
    );
    for (final moonUp in [false, true]) {
      final sky = skies.firstWhere(
        (sky) => sky.visibility(visible)?.moonUp == moonUp,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TonightResults(
              ngcPageSource: () =>
                  () async => null,
              sky: sky,
              targets: [visible],
              onRefresh: () {},
              onOpenObject: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('M 31 · Spiral Galaxy'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip('Visibility details: Visible in darkness tonight'),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Moon up at best time'),
        moonUp ? findsOneWidget : findsNothing,
      );
      expect(find.textContaining('Moon below horizon'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('loads NGC pages as the list is scrolled and opens NGC titles', (
    tester,
  ) async {
    final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));
    var fetched = 0;
    ObservingTarget? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightResults(
            sky: sky,
            targets: const [],
            ngcPageSource: () => () async {
              if (fetched == 2) return null;
              final start = fetched++ * 80;
              return List.generate(
                80,
                (index) => ObservingTarget.ngc(
                  start + index + 1,
                  'Cluster',
                  null,
                  start + index + 1,
                  const RightAscession(0, 0),
                  const Declination(90, 0, '+'),
                ),
              );
            },
            onRefresh: () {},
            onOpenObject: (target) => opened = target,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(fetched, 1);
    await tester.scrollUntilVisible(
      find.text('NGC 81 · Cluster'),
      500,
      scrollable: find.byType(Scrollable),
      maxScrolls: 60,
    );
    await tester.pumpAndSettle();
    expect(fetched, 2);
    await tester.tap(find.text('NGC 81 · Cluster'));
    expect(opened?.isNgc, isTrue);
    expect(opened?.number, 81);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports and retries an NGC page error', (tester) async {
    final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightResults(
            sky: sky,
            targets: [visible],
            ngcPageSource: () => () async {
              if (requests++ == 0) throw StateError('offline');
              return null;
            },
            onRefresh: () {},
            onOpenObject: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Could not load NGC catalog:'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.textContaining('Could not load NGC catalog:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh reloads location and resubscribes to the catalog', (
    tester,
  ) async {
    var locationRequests = 0;
    var catalogRequests = 0;
    final location = gps.LocationData.fromMap({
      'latitude': 40.7128,
      'longitude': -74.006,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightPage(
            observationsProvider: () => Stream.value([]),
            checklistProvider: () => Stream.value(<String>{}),
            ngcPageSource: () =>
                () async => null,
            locationProvider: () async {
              locationRequests++;
              return location;
            },
            catalogProvider: () {
              catalogRequests++;
              return Stream.value([visible]);
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('What’s visible tonight?'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh location and times'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('What’s visible tonight?'), findsOneWidget);
    expect(locationRequests, 2);
    expect(catalogRequests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open screen switches to the upcoming night after dawn', (
    tester,
  ) async {
    final latitude = 40.0;
    final longitude = -74.0;
    final dawn = TonightSky(
      latitude,
      longitude,
      DateTime.utc(2024, 9, 23, 8),
    ).darkness.single.end;
    final clockStart = tester.binding.clock.now();
    final location = gps.LocationData.fromMap({
      'latitude': latitude,
      'longitude': longitude,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightPage(
            observationsProvider: () => Stream.value([]),
            checklistProvider: () => Stream.value(<String>{}),
            ngcPageSource: () =>
                () async => null,
            locationProvider: () async => location,
            catalogProvider: () => Stream.value([visible]),
            clock: () => dawn
                .subtract(const Duration(seconds: 5))
                .add(tester.binding.clock.now().difference(clockStart)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Observing night: Sun, Sep 22 – Mon, Sep 23 (local time)'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(
      find.text('Observing night: Mon, Sep 23 – Tue, Sep 24 (local time)'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('object details fit on a narrow screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sky = TonightSky(40.7128, -74.006, DateTime.utc(2024, 9, 22, 18));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: TonightResults(
              ngcPageSource: () =>
                  () async => null,
              sky: sky,
              targets: [visible],
              checklistObjectIds: const {},
              onToggleChecklist: (_) {},
              onRefresh: () {},
              onOpenObject: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('M 31 · Spiral Galaxy'),
      find.byType(ListView),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    expect(find.text('M 31 · Spiral Galaxy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains polar summer without claiming objects are visible', (
    tester,
  ) async {
    final sky = TonightSky(78.2, 15.6, DateTime.utc(2024, 6, 21, 18));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightResults(
            ngcPageSource: () =>
                () async => null,
            sky: sky,
            targets: [visible],
            onRefresh: () {},
            onOpenObject: (_) {},
          ),
        ),
      ),
    );
    expect(
      find.textContaining('No astronomical darkness this observing night'),
      findsOneWidget,
    );
    expect(find.text('Visible Messier and NGC objects'), findsOneWidget);
    expect(
      find.textContaining('No objects are listed because'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports when no catalog objects are visible', (tester) async {
    final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TonightResults(
            ngcPageSource: () =>
                () async => null,
            sky: sky,
            targets: const [],
            onRefresh: () {},
            onOpenObject: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No catalog objects are above the horizon during astronomical darkness.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
