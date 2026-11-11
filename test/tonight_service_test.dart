import 'package:astro_log/ra_dec.dart';
import 'package:astro_log/list_of_objects.dart';
import 'package:astro_log/services/tonight_service.dart';
import 'package:astro_log/uploadobjects.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Sun, twilight and Moon events agree with New York almanac', () {
    // timeanddate.com, New York, 22–23 September 2024 (EDT = UTC-4).
    final sky = TonightSky(40.7128, -74.006, DateTime.utc(2024, 9, 22, 18));
    void near(DateTime actual, DateTime expected) {
      expect(
        actual.difference(expected).abs(),
        lessThan(const Duration(minutes: 8)),
      );
    }

    near(
      sky.sunEvents.singleWhere((e) => !e.rising).time,
      DateTime.utc(2024, 9, 22, 22, 52),
    );
    near(
      sky.sunEvents.singleWhere((e) => e.rising).time,
      DateTime.utc(2024, 9, 23, 10, 45),
    );
    near(sky.darkness.single.start, DateTime.utc(2024, 9, 23, 0, 23));
    near(sky.darkness.single.end, DateTime.utc(2024, 9, 23, 9, 13));
    near(
      sky.moonEvents.singleWhere((e) => e.rising).time,
      DateTime.utc(2024, 9, 23, 1, 31),
    );
    near(
      sky.moonEvents.singleWhere((e) => !e.rising).time,
      DateTime.utc(2024, 9, 22, 16, 24),
    );
  });

  test('before astronomical dawn retains the ongoing observing night', () {
    final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 23, 2));
    expect(sky.start, DateTime.utc(2024, 9, 22, 12));
    expect(sky.end, DateTime.utc(2024, 9, 23, 12));
  });

  test('after astronomical dawn shows the upcoming observing night', () {
    final beforeDawn = TonightSky(40, -74, DateTime.utc(2024, 9, 23, 8));
    final dawn = beforeDawn.darkness.single.end;
    expect(
      TonightSky(40, -74, dawn.subtract(const Duration(seconds: 1))).start,
      DateTime.utc(2024, 9, 22, 12),
    );
    expect(TonightSky(40, -74, dawn).start, DateTime.utc(2024, 9, 23, 12));
    expect(
      TonightSky(40, -74, DateTime.utc(2024, 9, 23, 10)).start,
      DateTime.utc(2024, 9, 23, 12),
    );
  });

  test('polar summer has no astronomical darkness', () {
    final sky = TonightSky(78.2, 15.6, DateTime.utc(2024, 6, 21, 18));
    expect(sky.darkness, isEmpty);
    expect(sky.sunEvents, isEmpty);
  });

  test('polar winter can remain dark for the whole interval', () {
    final sky = TonightSky(89, 15.6, DateTime.utc(2024, 12, 21, 18));
    expect(sky.darkness.single.start, sky.start);
    expect(sky.darkness.single.end, sky.end);
  });

  test('targets are filtered by altitude during darkness', () {
    final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));
    const north = ObservingTarget(
      1,
      'Cluster',
      null,
      null,
      RightAscession(0, 0),
      Declination(90, 0, '+'),
    );
    const south = ObservingTarget(
      2,
      'Galaxy',
      null,
      null,
      RightAscession(0, 0),
      Declination(90, 0, '-'),
    );
    final visible = sky.visibility(north);
    expect(visible, isNotNull);
    expect(visible!.altitudeDegrees, closeTo(40, 0.1));
    expect(visible.bestTime.isBefore(sky.darkness.single.start), isFalse);
    expect(visible.bestTime.isAfter(sky.darkness.single.end), isFalse);
    expect(visible.intervals.single.start, sky.darkness.single.start);
    expect(visible.intervals.single.end, sky.darkness.single.end);
    expect(sky.visibility(south), isNull);
  });

  test('visible intervals are clipped to darkness and horizon crossings', () {
    final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));
    const rising = ObservingTarget(
      1,
      'Galaxy',
      null,
      null,
      RightAscession(6, 0),
      Declination(0, 0, '+'),
    );
    const setting = ObservingTarget(
      2,
      'Galaxy',
      null,
      null,
      RightAscession(18, 0),
      Declination(0, 0, '+'),
    );
    final rise = sky.visibility(rising)!.intervals.single;
    final set = sky.visibility(setting)!.intervals.single;
    expect(
      rise.start.difference(DateTime.utc(2024, 9, 23, 4, 45)).abs(),
      lessThan(const Duration(minutes: 10)),
    );
    expect(rise.end, sky.darkness.single.end);
    expect(set.start, sky.darkness.single.start);
    expect(
      set.end.difference(DateTime.utc(2024, 9, 23, 4, 45)).abs(),
      lessThan(const Duration(minutes: 10)),
    );
  });

  test('detects a short visibility window around transit', () {
    final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));
    const target = ObservingTarget(
      1,
      'Galaxy',
      null,
      null,
      RightAscession(0, 0),
      Declination(49, 59.9, '-'),
    );
    final result = sky.visibility(target)!;
    expect(result.intervals, hasLength(1));
    final interval = result.intervals.single;
    expect(
      interval.end.difference(interval.start),
      lessThan(const Duration(minutes: 10)),
    );
    expect(result.bestTime.isAfter(interval.start), isTrue);
    expect(result.bestTime.isBefore(interval.end), isTrue);
  });

  test('a full dark day can contain two separate visibility windows', () {
    final sky = TonightSky(89, 15.6, DateTime.utc(2024, 12, 21, 18));
    for (var hour = 0; hour < 24; hour++) {
      final target = ObservingTarget(
        hour,
        'Galaxy',
        null,
        null,
        RightAscession(hour, 0),
        const Declination(0, 0, '+'),
      );
      final intervals = sky.visibility(target)?.intervals ?? [];
      if (intervals.length == 2) {
        expect(intervals.first.start, sky.start);
        expect(intervals.last.end, sky.end);
        expect(intervals.first.end.isBefore(intervals.last.start), isTrue);
        return;
      }
    }
    fail('Expected a target with two separate visibility windows');
  });

  test('best time finds the transit within the darkness interval', () {
    final sky = TonightSky(40.7128, -74.006, DateTime.utc(2024, 9, 22, 18));
    const target = ObservingTarget(
      31,
      'Galaxy',
      null,
      3.4,
      RightAscession(0, 42.7),
      Declination(41, 16, '+'),
    );
    final result = sky.visibility(target)!;
    expect(result.bestTime.isAfter(sky.darkness.single.start), isTrue);
    expect(result.bestTime.isBefore(sky.darkness.single.end), isTrue);
    expect(result.altitudeDegrees, closeTo(89.45, 0.1));
  });

  test('parses existing Firestore records without magnitude', () {
    final target = ObservingTarget.fromMessierJson({
      'number': 1,
      'type': 'Supernova Remnant',
      'ra': {'hour': 5, 'minute': 34.5},
      'dec': {'degree': 22, 'minute': 1, 'sign': '+'},
    });
    expect(target.number, 1);
    expect(target.type, 'Supernova Remnant');
    expect(target.magnitude, isNull);
    expect(target.ra.hours, closeTo(5.575, 0.001));
  });

  test('pages merge by brightness, omit linked and hidden NGCs, and keep unknowns last', () async {
    final sky = TonightSky(40, -74, DateTime.utc(2024, 9, 22, 18));
    const north = Declination(90, 0, '+');
    const south = Declination(90, 0, '-');
    const ra = RightAscession(0, 0);
    final pages = <List<ObservingTarget>>[
      [
        const ObservingTarget.ngc(2, 'Galaxy', null, 1, ra, north),
        const ObservingTarget.ngc(224, 'Galaxy', null, 1.5, ra, north),
        const ObservingTarget.ngc(3, 'Galaxy', null, 3, ra, north),
        const ObservingTarget.ngc(4, 'Galaxy', null, 4, ra, south),
      ],
      [
        const ObservingTarget.ngc(5, 'Galaxy', null, 5, ra, north, [31]),
        const ObservingTarget.ngc(6, 'Galaxy', null, null, ra, north),
      ],
    ];
    var fetched = 0;
    final pager = ObservingPager(sky, [
      const ObservingTarget(31, 'Galaxy', null, 2, ra, north, [224]),
      const ObservingTarget(1, 'Cluster', null, null, ra, north),
    ], () async => fetched < pages.length ? pages[fetched++] : null);
    await pager.loadMore(limit: 2);
    expect(fetched, 1);
    expect(pager.results.map((entry) => entry.target.number), [2, 31]);
    await pager.loadMore(limit: 10);
    expect(pager.done, isTrue);
    expect(pager.results.map((entry) => entry.target.number), [2, 31, 3, 1, 6]);
    expect(pager.results.map((entry) => entry.target.magnitude), [
      1,
      2,
      3,
      null,
      null,
    ]);
  });

  test('catalog import includes apparent magnitudes', () async {
    final catalog = parseMessierCsv(
      await rootBundle.loadString('assets/messier.csv'),
    );
    expect(catalog, hasLength(110));
    expect(catalog.first.json['magnitude'], 8.4);
    expect(catalog.first.json['designation'], 'NGC 1952 Crab Nebula');
    expect(catalog.first.json['constellation'], 'Taurus');
    expect(catalog.first.json['size'], '6.0x4.0');
    expect(catalog.first.json['distanceLightYears'], 6300);
    expect(catalog.first.json['viewingSeason'], 'Winter');
    expect(catalog.last.json['magnitude'], 8.5);
  });

  test('NGC import parses catalog data and skips missing values', () async {
    final catalog = parseNGCCsv(
      await rootBundle.loadString('assets/NGCObjects.csv'),
    );
    expect(catalog, hasLength(7840));
    expect(catalog.first.json['number'], 1);
    expect(catalog.first.json['designation'], 'UGC 57');
    expect(catalog.first.json['constellation'], 'Pegasus');
    expect(catalog.first.json['magnitude'], 13);
    expect(catalog.first.json['info'], 'Size: 1.9  F, S, R, bet *11 and *14');
    expect(catalog[3].json.containsKey('designation'), isFalse);
    expect(catalog[3].json.containsKey('magnitude'), isFalse);
  });

  test(
    'NGC updates expand only matching legacy constellation abbreviations',
    () {
      final object = parseNGCCsv(
        'ObjectNum,Name,Type,Constellation,Magnitude,Info,RAHour,RAMinute,DecSign,DecDeg,DecMinute\n'
        '1,UGC 57,Galaxy,Pegasus,13,Notes,0,7.3,+,27,43',
      ).single;
      expect(
        ngcUpdates(object, {'constellation': 'Peg'})['constellation'],
        'Pegasus',
      );
      expect(
        ngcUpdates(object, {
          'constellation': 'Pegasus',
        }).containsKey('constellation'),
        isFalse,
      );
      expect(
        ngcUpdates(object, {
          'constellation': 'And',
        }).containsKey('constellation'),
        isFalse,
      );
      expect(
        ngcUpdates(object, {
          'constellation': 'Custom',
        }).containsKey('constellation'),
        isFalse,
      );
    },
  );

  test('NGC import omits literal nulls instead of storing text', () {
    final catalog = parseNGCCsv(
      'ObjectNum,Name,Type,Constellation,Magnitude,Info,RAHour,RAMinute,DecSign,DecDeg,DecMinute\n'
      '1,null,Galaxy,NULL,null,null,0,7.3,+,27,43',
    );
    final data = catalog.single.json;
    expect(data.containsKey('designation'), isFalse);
    expect(data.containsKey('constellation'), isFalse);
    expect(data.containsKey('magnitude'), isFalse);
    expect(data.containsKey('info'), isFalse);
  });

  test(
    'NGC updates remove legacy null difficulty but preserve real values',
    () {
      final catalog = parseNGCCsv(
        'ObjectNum,Name,Type,Constellation,Magnitude,Info,RAHour,RAMinute,DecSign,DecDeg,DecMinute\n'
        '1,UGC 57,Galaxy,Peg,13,Notes,0,7.3,+,27,43',
      );
      final updates = ngcUpdates(catalog.single, {
        'number': 1,
        'difficulty': 'null',
        'magnitude': 10,
      });
      expect(updates['difficulty'], isA<FieldValue>());
      expect(updates.containsKey('magnitude'), isFalse);
      expect(updates['designation'], 'UGC 57');
      final existing = ngcUpdates(catalog.single, {'difficulty': 'Hard'});
      expect(existing.containsKey('difficulty'), isFalse);
    },
  );

  test(
    'catalog links include both NGC designations and related objects',
    () async {
      final messier = parseMessierCsv(
        await rootBundle.loadString('assets/messier.csv'),
      );
      final ngc = parseNGCCsv(
        await rootBundle.loadString('assets/NGCObjects.csv'),
      );
      final links = buildCatalogLinks(messier, ngc);
      expect(links.length, 107);
      expect(
        links.values.fold<int>(0, (total, entries) => total + entries.length),
        108,
      );
      expect(links[1], {1952});
      expect(links[24], {6603});
      expect(links[76], {650, 651});
      expect(links[102], {5866});
      expect(links.containsKey(25), isFalse);
      expect(links.containsKey(40), isFalse);
      expect(links.containsKey(45), isFalse);
    },
  );

  test('NGC observations mark linked Messier entries viewed', () {
    final m24 = {
      'number': 24,
      'ngcNumbers': [6603],
    };
    expect(
      messierWasViewed(m24, [
        {'ngc': 6603},
      ]),
      isTrue,
    );
    expect(
      messierWasViewed(m24, [
        {'messier': 24},
      ]),
      isTrue,
    );
    expect(
      messierWasViewed(m24, [
        {'ngc': 1},
      ]),
      isFalse,
    );
    expect(
      messierWasViewed(
        {'number': 24},
        [
          {'ngc': 6603},
        ],
      ),
      isFalse,
    );
  });
}
