import 'dart:math' as math;

import 'package:astronomia/astronomia.dart' as astro;
import 'package:astronomia/moonillum.dart' as moonillum;
import 'package:astronomia/moonposition.dart' as moon;
import 'package:astronomia/solar.dart' as solar;

import '../models/observing_target.dart';

bool hasKnownMagnitude(ObservingTarget target) =>
    target.magnitude != null && target.magnitude!.isFinite;

int compareBrightness(ObservingTarget a, ObservingTarget b) {
  final aKnown = hasKnownMagnitude(a);
  final bKnown = hasKnownMagnitude(b);
  if (aKnown != bKnown) return aKnown ? -1 : 1;
  return aKnown ? a.magnitude!.compareTo(b.magnitude!) : 0;
}

/// Merges the small Messier catalog with NGC pages already sorted by magnitude.
class ObservingPager {
  final TonightSky sky;
  final Future<List<ObservingTarget>?> Function() nextNgcPage;
  final List<TargetVisibility> _messier;
  final Set<int> _linkedNgc;
  final Set<int> _messierNumbers;
  final List<TargetVisibility> results = [];
  final List<TargetVisibility> _ngc = [];
  int _messierIndex = 0;
  int _ngcIndex = 0;
  bool _ngcDone = false;
  bool _cancelled = false;
  bool done = false;

  ObservingPager(this.sky, List<ObservingTarget> messier, this.nextNgcPage)
    : _linkedNgc = messier.expand((target) => target.ngcNumbers).toSet(),
      _messierNumbers = messier.map((target) => target.number).toSet(),
      _messier =
          messier.map(sky.visibility).whereType<TargetVisibility>().toList()
            ..sort((a, b) => compareBrightness(a.target, b.target));

  Future<void> loadMore({int limit = 25}) async {
    final end = results.length + limit;
    while (results.length < end && !_cancelled) {
      while (_ngcIndex == _ngc.length && !_ngcDone) {
        final page = await nextNgcPage();
        if (_cancelled) return;
        if (page == null) {
          _ngcDone = true;
          break;
        }
        _ngc
          ..clear()
          ..addAll(
            page
                .where(
                  (target) =>
                      !_linkedNgc.contains(target.number) &&
                      !target.messierNumbers.any(_messierNumbers.contains),
                )
                .map(sky.visibility)
                .whereType<TargetVisibility>(),
          );
        _ngcIndex = 0;
      }
      final nextMessier = _messierIndex < _messier.length
          ? _messier[_messierIndex]
          : null;
      final nextNgc = _ngcIndex < _ngc.length ? _ngc[_ngcIndex] : null;
      if (nextMessier == null && nextNgc == null) {
        done = true;
        break;
      }
      if (nextMessier != null &&
          (nextNgc == null ||
              compareBrightness(nextMessier.target, nextNgc.target) <= 0)) {
        results.add(nextMessier);
        _messierIndex++;
      } else {
        results.add(nextNgc!);
        _ngcIndex++;
      }
    }
  }

  void cancel() => _cancelled = true;
}

class TimeInterval {
  final DateTime start;
  final DateTime end;
  const TimeInterval(this.start, this.end);
}

class SkyEvent {
  final DateTime time;
  final bool rising;
  const SkyEvent(this.time, this.rising);
}

class TargetVisibility {
  final ObservingTarget target;
  final DateTime bestTime;
  final double altitudeDegrees;
  final List<TimeInterval> intervals;
  final double Function(DateTime) _moonAltitude;
  late final bool moonUp = _moonAltitude(bestTime) > 0.125;

  TargetVisibility(
    this.target,
    this.bestTime,
    this.altitudeDegrees,
    this.intervals,
    this._moonAltitude,
  );
}

/// Approximate events for the local observing night, noon to the next noon.
class TonightSky {
  final double latitude;
  final double longitude;
  final DateTime start;
  late final DateTime end = start.isUtc
      ? DateTime.utc(start.year, start.month, start.day + 1, 12)
      : DateTime(start.year, start.month, start.day + 1, 12);

  TonightSky._(this.latitude, this.longitude, this.start);

  factory TonightSky(double latitude, double longitude, DateTime now) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ArgumentError('Invalid observing coordinates');
    }
    DateTime noon(int day) => now.isUtc
        ? DateTime.utc(now.year, now.month, day, 12)
        : DateTime(now.year, now.month, day, 12);

    if (now.hour < 12) {
      final previous = TonightSky._(latitude, longitude, noon(now.day - 1));
      // Retain the current observing night until its last dark interval ends.
      if (previous.darkness.any((interval) => interval.end.isAfter(now))) {
        return previous;
      }
    }
    return TonightSky._(latitude, longitude, noon(now.day));
  }

  static const _radians = math.pi / 180;
  double _jd(DateTime time) =>
      time.toUtc().millisecondsSinceEpoch / 86400000 + 2440587.5;

  double _altitude(DateTime time, double ra, double dec) {
    final sidereal = astro.mean(_jd(time)) * 2 * math.pi / 86400;
    final hourAngle = sidereal + longitude * _radians - ra;
    final lat = latitude * _radians;
    final sine =
        math.sin(lat) * math.sin(dec) +
        math.cos(lat) * math.cos(dec) * math.cos(hourAngle);
    return math.asin(sine.clamp(-1.0, 1.0)) / _radians;
  }

  double sunAltitude(DateTime time) {
    final position = solar.apparentEquatorial(_jd(time));
    return _altitude(time, position.ra, position.dec);
  }

  double moonAltitude(DateTime time) {
    final jd = _jd(time);
    final position = moon.position(jd);
    final obliquity = astro.meanObliquity(jd);
    final eq = astro.eclToEq(
      position.lon,
      position.lat,
      math.sin(obliquity),
      math.cos(obliquity),
    );
    return _altitude(time, eq.ra, eq.dec);
  }

  double moonIllumination(DateTime time) =>
      moonillum.illuminated(moonillum.phaseAngle3(_jd(time)));

  /// Detect crossings and refine to within a minute.
  List<SkyEvent> _crossings(double Function(DateTime) altitude, double limit) {
    final events = <SkyEvent>[];
    var left = start;
    var leftValue = altitude(left) - limit;
    while (left.isBefore(end)) {
      var right = left.add(const Duration(minutes: 10));
      if (right.isAfter(end)) right = end;
      final rightValue = altitude(right) - limit;
      if ((leftValue < 0 && rightValue >= 0) ||
          (leftValue >= 0 && rightValue < 0)) {
        var low = left;
        var high = right;
        while (high.difference(low) > const Duration(seconds: 30)) {
          final mid = low.add(high.difference(low) ~/ 2);
          if ((altitude(mid) - limit >= 0) == (leftValue >= 0)) {
            low = mid;
          } else {
            high = mid;
          }
        }
        events.add(
          SkyEvent(low.add(high.difference(low) ~/ 2), rightValue >= 0),
        );
      }
      left = right;
      leftValue = rightValue;
    }
    return events;
  }

  late final List<SkyEvent> sunEvents = _crossings(sunAltitude, -0.833);
  // The geocentric threshold includes approximate lunar parallax and refraction.
  late final List<SkyEvent> moonEvents = _crossings(moonAltitude, 0.125);
  late final List<SkyEvent> twilightEvents = _crossings(sunAltitude, -18);

  late final List<TimeInterval> darkness = () {
    final intervals = <TimeInterval>[];
    DateTime? darkStart = sunAltitude(start) < -18 ? start : null;
    for (final event in twilightEvents) {
      if (!event.rising) {
        darkStart = event.time;
      } else if (darkStart != null) {
        intervals.add(TimeInterval(darkStart, event.time));
        darkStart = null;
      }
    }
    if (darkStart != null) intervals.add(TimeInterval(darkStart, end));
    return intervals;
  }();

  TargetVisibility? visibility(ObservingTarget target) {
    DateTime? best;
    var maxAltitude = 0.0;
    final visibleIntervals = <TimeInterval>[];
    for (final interval in darkness) {
      final sidereal = astro.mean(_jd(interval.start)) * 2 * math.pi / 86400;
      final untilTransit =
          (target.ra.radian - longitude * _radians - sidereal) % (2 * math.pi);
      const siderealDayMicros = 86164.0905 * 1e6;
      final transit = interval.start.add(
        Duration(
          microseconds: (untilTransit / (2 * math.pi) * siderealDayMicros)
              .round(),
        ),
      );
      final boundaries = <DateTime>[interval.start, interval.end];
      // Altitude is monotonic between upper and lower transits.
      for (final angle in [
        untilTransit,
        (untilTransit + math.pi) % (2 * math.pi),
      ]) {
        var extremum = interval.start.add(
          Duration(
            microseconds: (angle / (2 * math.pi) * siderealDayMicros).round(),
          ),
        );
        while (extremum.isBefore(interval.end)) {
          if (extremum.isAfter(interval.start)) boundaries.add(extremum);
          extremum = extremum.add(
            Duration(microseconds: siderealDayMicros.round()),
          );
        }
      }
      boundaries.sort();
      DateTime? visibleStart =
          _altitude(interval.start, target.ra.radian, target.dec.radian) > 0
          ? interval.start
          : null;
      for (var i = 0; i < boundaries.length - 1; i++) {
        var left = boundaries[i];
        var right = boundaries[i + 1];
        final leftUp = _altitude(left, target.ra.radian, target.dec.radian) > 0;
        final rightUp =
            _altitude(right, target.ra.radian, target.dec.radian) > 0;
        if (leftUp == rightUp) continue;
        while (right.difference(left) > const Duration(seconds: 30)) {
          final mid = left.add(right.difference(left) ~/ 2);
          if ((_altitude(mid, target.ra.radian, target.dec.radian) > 0) ==
              leftUp) {
            left = mid;
          } else {
            right = mid;
          }
        }
        final crossing = left.add(right.difference(left) ~/ 2);
        if (rightUp) {
          visibleStart = crossing;
        } else if (visibleStart != null) {
          visibleIntervals.add(TimeInterval(visibleStart, crossing));
          visibleStart = null;
        }
      }
      if (visibleStart != null) {
        visibleIntervals.add(TimeInterval(visibleStart, interval.end));
      }
      // A fixed target reaches its maximum at transit or at an interval edge.
      for (final time in [
        interval.start,
        if (!transit.isAfter(interval.end)) transit,
        interval.end,
      ]) {
        final altitude = _altitude(time, target.ra.radian, target.dec.radian);
        if (altitude > maxAltitude) {
          best = time;
          maxAltitude = altitude;
        }
      }
    }
    return best == null
        ? null
        : TargetVisibility(
            target,
            best,
            maxAltitude,
            visibleIntervals,
            moonAltitude,
          );
  }
}
