import 'package:astro_log/gallary_tile.dart';
import 'package:astro_log/generated/l10n.dart';
import 'package:astro_log/models/observation_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

// ignore: subtype_of_sealed_class
/// Records writes made to an observation document.
class _ObservationReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _ObservationReference([this.path = 'users/test/observations/one']);

  final updates = <Map<Object, Object?>>[];

  @override
  final String path;

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updates.add(data);
  }
}

// ignore: subtype_of_sealed_class
/// Supplies equipment data for the gallery details.
class _EquipmentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  Map<String, dynamic> data() => {
    'telescope': 'Refractor',
    'aperture': 100,
    'focalLength': 700,
    'mount': 'Alt-azimuth',
  };
}

// ignore: subtype_of_sealed_class
/// Returns a deterministic equipment snapshot.
class _EquipmentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _EquipmentSnapshot();
}

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
            observation: ObservationData(
              title: 'Observation',
              dateTime: DateTime(2024, 9, 22, 21),
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

  testWidgets('model notes are edited separately and saved to its reference', (
    tester,
  ) async {
    await S.load(const Locale('en'));
    await initializeDateFormatting();
    final reference = _ObservationReference();
    final observation = ObservationData(
      title: 'M 31',
      dateTime: DateTime(2024, 9, 22, 21),
      latitude: 40,
      longitude: -74,
      location: 'Home',
      notes: const [],
      reference: reference,
      equipmentReference: _EquipmentReference(),
    );
    addTearDown(selectedTiles.clear);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GallaryTile(observation: observation)),
      ),
    );
    await tester.pump();
    await tester.longPress(find.text('M 31'));
    await tester.pump();
    expect(selectedTiles, [reference]);
    await tester.tap(find.text('M 31'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Refractor'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_box_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Clear sky');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Clear sky'),
      200,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Clear sky'), findsOneWidget);
    expect(observation.notes, isEmpty);
    await tester.tap(find.text(S.current.closeDetails));
    await tester.pumpAndSettle();
    expect(reference.updates, [
      {
        'notes': ['Clear sky'],
      },
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacing a tile keeps open detail edits on the original', (
    tester,
  ) async {
    await S.load(const Locale('en'));
    await initializeDateFormatting();
    final firstReference = _ObservationReference();
    final secondReference = _ObservationReference(
      'users/test/observations/two',
    );
    ObservationData observation(
      String title,
      DocumentReference reference, {
      List<String> notes = const [],
    }) => ObservationData(
      title: title,
      dateTime: DateTime(2024, 9, 22, 21),
      latitude: 40,
      longitude: -74,
      location: 'Home',
      reference: reference,
      notes: notes,
    );
    Widget gallery(ObservationData data) => MaterialApp(
      home: Scaffold(body: GallaryTile(observation: data)),
    );

    await tester.pumpWidget(gallery(observation('First', firstReference)));
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_box_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'First note');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      gallery(observation('Second', secondReference, notes: ['Second note'])),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.closeDetails));
    await tester.pumpAndSettle();
    expect(firstReference.updates, [
      {
        'notes': ['First note'],
      },
    ]);
    expect(secondReference.updates, isEmpty);
    expect(find.text('Second'), findsOneWidget);

    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Second note'),
      200,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Second note'), findsOneWidget);
    expect(find.text('First note'), findsNothing);
    await tester.tap(find.text(S.current.closeDetails));
    await tester.pumpAndSettle();
    expect(secondReference.updates, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
