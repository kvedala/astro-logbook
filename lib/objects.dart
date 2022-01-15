import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as gps;

import 'uploadobjects.dart';

extension on gps.LocationData {
  double? get latitudeRad => this.latitude! * pi / 180;
  double? get longitudeRad => this.longitude! * pi / 180;
}

/// Generic Celestial object catalog
abstract class Catalog extends StatelessWidget {
  /// name of the catalog
  final String name;

  /// object catalog index
  final int id;

  /// type of object
  final String type;

  final RightAscession ra;
  final Declination dec;

  /// observing difficulty
  final String? difficulty;

  /// absolute magnitude of the object
  final num? magnitude;

  /// was this object viewed by the user
  final bool viewed;

  Catalog(this.id, this.ra, this.dec,
      {required this.name,
      this.difficulty,
      this.type = "",
      this.magnitude,
      this.viewed = false});

  @override
  Widget build(BuildContext context) {
    final times = getRiseAndSetTime();
    late Widget visible;
    if (times == null)
      visible = SizedBox();
    else if (times.belowHorizon)
      visible = Icon(Icons.cancel);
    else if (times.circumpolar ||
        times.riseTime!.hour >= 18 ||
        times.setTime!.hour <= 5) {
      visible = Icon(Icons.done);
    } else {
      visible = Icon(Icons.cancel);
    }
    return ListTile(
      visualDensity: VisualDensity.compact,
      dense: true,
      leading: Column(children: [
        Text("M $id"),
        Icon(
            viewed ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      ]),
      subtitle: Table(children: [
        TableRow(children: [
          Text("RA: ${ra.toString()}"),
          Text(type),
          times == null
              ? SizedBox()
              : times.circumpolar
                  ? Text("Circumpolar")
                  : times.belowHorizon
                      ? Text("Below Horizon")
                      : Text(
                          "Rise: ${DateFormat("HH:mm").format(times.riseTime!)}"),
        ]),
        TableRow(children: [
          Text("DEC: ${dec.toString()}"),
          Text(difficulty ?? ""),
          times == null
              ? SizedBox()
              : (times.circumpolar | times.belowHorizon)
                  ? SizedBox()
                  : Text("Set: ${DateFormat("HH:mm").format(times.setTime!)}"),
        ]),
      ]),
      trailing: visible,
    );
  }
}

/// Convenience class to store Messier Objects.
/// Displays as a list tile.
class Messier extends Catalog {
  Messier(int id, String type, RightAscession ra, Declination dec,
      {String? difficulty, num? magnitude, bool viewed = false})
      : super(id, ra, dec,
            name: "Messier",
            difficulty: difficulty,
            type: type,
            magnitude: magnitude,
            viewed: viewed);

  factory Messier.fromJSON(Map<String, dynamic> json, [bool viewed = false]) {
    return Messier(
      json['number'],
      json['type'],
      RightAscession.fromJSON(json['ra']['degree']),
      Declination.fromJSON(json['dec']['degree']),
      difficulty: json['difficulty'],
      viewed: viewed,
    );
  }

  /// Export to JSON format Map
  Map<String, dynamic> get json => {
        "number": id,
        "type": type,
        "ra": ra.json,
        "dec": dec.json,
        "difficulty": difficulty.toString()
      };

  _RiseSetTimes? getRiseAndSetTime() {
    if (location == null) return null;
    return _RiseSetTimes.forObject(ra, dec, location!);
  }
}

/// http://www2.arnes.si/~gljsentvid10/sidereal.htm
///
/// Shamelessly translated from
/// https://github.com/codebox/star-rise-and-set-times/blob/master/calc.js
class _RiseSetTimes {
  final DateTime? riseTime;
  final DateTime? setTime;
  final bool belowHorizon;
  final bool circumpolar;

  _RiseSetTimes({
    this.riseTime,
    this.setTime,
    this.belowHorizon = false,
    this.circumpolar = false,
  });

  // factory _RiseSetTimes.fromMillisecondsSinceEpoch({
  //   required num riseTimeMilliseconds,
  //   required num setTimeMilliseconds,
  //   bool belowHorizon = false,
  //   bool circumpolar = false,
  // }) =>
  //     _RiseSetTimes(
  //         riseTime:
  //             DateTime.fromMillisecondsSinceEpoch(riseTimeMilliseconds.round()),
  //         setTime:
  //             DateTime.fromMillisecondsSinceEpoch(setTimeMilliseconds.round()),
  //         belowHorizon: belowHorizon,
  //         circumpolar: circumpolar);

  static const MINUTES_PER_HOUR = 60;
  static const SECONDS_PER_HOUR = 60;
  static const SECONDS_PER_MINUTE = 60;
  static const HOURS_PER_DAY = 24;
  static const MILLISECONDS_PER_SECOND = 1000;
  static const MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;
  static const SECONDS_PER_DAY = SECONDS_PER_MINUTE * MINUTES_PER_DAY;
  static const MILLISECONDS_PER_DAY = SECONDS_PER_DAY * MILLISECONDS_PER_SECOND;
  static const EPOCH_MILLIS_AT_2000_01_01_12_00_00 = 946728000000;

  /// Convert [timeInHours] to a DateTime object
  static TimeOfDay hoursToClockTime(num timeInHours) {
    final hours = timeInHours.floor();
    final minutes = ((timeInHours - hours) * MINUTES_PER_HOUR).floor();
    // final seconds = ((timeInHours - hours - minutes / MINUTES_PER_HOUR) * SECONDS_PER_HOUR).floor();

    return TimeOfDay(hour: hours, minute: minutes);
  }

  /// find all `n` such that
  /// `x_0 <= (n * m + r - a) / b <= x_1`
  static List<num> unmod(num r, num a, num b, num m, num x_0, num x_1) {
    // find all 'n' such that x_0 <= (n * m + r - a) / b <= x_1
    final fromN = ((x_0 * b + a - r) / m).ceil();
    final toN = ((x_1 * b + a - r) / m).floor();
    final xValues = <num>[];
    for (var n = fromN; n <= toN; n++) {
      xValues.add((n * m + r - a) / b);
    }
    return xValues;
  }

  static TimeOfDay radiansToUtcTime(
      double radians, gps.LocationData userLocation) {
    final daysSince_2000_01_01_12 = (DateTime.now().millisecondsSinceEpoch -
            EPOCH_MILLIS_AT_2000_01_01_12_00_00) /
        MILLISECONDS_PER_DAY;
    final prevMidDay = (daysSince_2000_01_01_12).floor();
    // https://aa.usno.navy.mil/faq/docs/GAST.php
    final days = unmod(
        radians,
        4.894961212735792 + (userLocation.longitudeRad!),
        6.30038809898489,
        2 * pi,
        prevMidDay,
        prevMidDay + 1)[0];
    final millisSinceEpoch =
        days * MILLISECONDS_PER_DAY + EPOCH_MILLIS_AT_2000_01_01_12_00_00;
    final millisSinceStartOfDay = millisSinceEpoch % MILLISECONDS_PER_DAY;
    final hoursSinceStartOfDay =
        millisSinceStartOfDay / (MILLISECONDS_PER_SECOND * SECONDS_PER_HOUR);
    return hoursToClockTime(hoursSinceStartOfDay);
  }

  factory _RiseSetTimes.forObject(
      RightAscession ra, Declination dec, gps.LocationData location) {
    if ((dec.degree - location.latitude!).abs() >= 90)
      return _RiseSetTimes(belowHorizon: true);
    if ((dec.degree + location.latitude!).abs() >= 90)
      return _RiseSetTimes(circumpolar: true);

    final c = acos(-tan(dec.radian) * tan(location.latitudeRad!));
    final riseTimeRadians = ra.radian - c;
    final setTimeRadians = ra.radian + c;

    return _RiseSetTimes(
      riseTime: radiansToUtcTime(riseTimeRadians, location).toDateTimeUTC(),
      setTime: radiansToUtcTime(setTimeRadians, location).toDateTimeUTC(),
    );
  }
}
