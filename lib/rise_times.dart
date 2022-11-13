import 'dart:math';

import 'package:flutter/material.dart';
import 'package:location/location.dart' as gps;

import 'ra_dec.dart';

extension on gps.LocationData {
  /// latitude value in radian
  double? get latRadian => latitude! * pi / 180;

  /// longitude value in radian
  // double? get longRadian => longitude! * pi / 180;
}

/// Supporting class for rise and set time computations
class RiseSetTimes {
  /// rise time for the object if not [circumpolar] and not [belowHorizon]
  final DateTime? riseTime;

  /// setting time for the object if not [circumpolar] and not [belowHorizon]
  final DateTime? setTime;

  /// true if the object is always below the horizon for the day
  final bool belowHorizon;

  /// true if the object is always circumpolar for the day
  final bool circumpolar;

  /// the computed values do not change once created
  const RiseSetTimes({
    this.riseTime,
    this.setTime,
    this.belowHorizon = false,
    this.circumpolar = false,
  });

  /// Supporting function to compute rise and set times for an object.
  ///
  /// Given the objects [RightAscession] and [Declination] and the user's
  /// [gps.LocationData], the algorithm first checks if the object will be
  /// [belowHorizon] or [circumpolar] and then computes the [riseTime] and
  /// [setTime] for the given date of [when]. If [when] is not provided, the
  /// times are calculated for today.
  factory RiseSetTimes.forObject(
          RightAscession ra, Declination dec, gps.LocationData location,
          [DateTime? when]) =>
      ((dec.degree - location.latitude!).abs() >= 90)
          ? const RiseSetTimes(belowHorizon: true)
          : ((dec.degree + location.latitude!).abs() >= 90)
              ? const RiseSetTimes(circumpolar: true)
              : _compute(ra, dec, location, when);

  /// Compute the rise and set times
  static RiseSetTimes _compute(
      RightAscession ra, Declination dec, gps.LocationData location,
      [DateTime? when]) {
    when ??= DateTime.now(); // if when was not defined
    final now = when.toUtc();

    // Step 1: calculate semi diurnal arc
    double H = acos(-tan(dec.radian) * tan(location.latRadian!)); // in radian
    H = H * 180 / pi; // in degree
    if (H < 0) {
      debugPrint("Got negative angle");
      H += 180;
    }
    // debugPrint("H: $H");
    // H = H / 15; // time in hours
    // Object rises (H) hours before and sets (H) hours after the LST
    // when LST = RA of the object

    // Step 2: Get UTC time using LST, Jualian Date and longitude.
    // 𝐿𝑆𝑇 = 100.46 + 0.985647 𝑑 + 𝐿𝑂𝑁 + 15 𝑈𝑇
    double ut = (ra.degree -
            100.46 -
            (0.985647 * _getJ2000(now)) -
            location.longitude!) /
        15;
    if (ut < 0 || ut >= 24) ut %= 24;
    // debugPrint("UT: $UT");
    // debugPrint("JD: ${_getJ2000(ra.hour, ra.minute, ra.second)}");

    // Step 3: Convert to Local date and time (local hour angle)
    final lha = DateTime.utc(now.year, now.month, now.day, ut.floor(),
        ((ut - ut.floor()) * 60).round());
    // debugPrint("LHA: ${LHA.toIso8601String()}");

    return RiseSetTimes(
      riseTime:
          lha.subtract(Duration(minutes: (H * 60 / 15).round())).toLocal(),
      setTime: lha.add(Duration(minutes: (H * 60 / 15).round())).toLocal(),
    );
  }

  /// Get Julian date number from the given [DateTime] value
  /// from J2000
  static double _getJ2000(DateTime when) {
    final now = when.toUtc();
    final y = now.year;
    final ut = now.hour + (now.minute + (now.second / 60)) / 60;

    return (367 * y) -
        (7 * (y + ((now.month + 9) / 12).floor()) / 4).floor() -
        (3 * (((y + (now.month - 9) / 7) / 100).floor() + 1) / 4).floor() +
        (275 * now.month / 9).floor() +
        now.day +
        // not adding hours - hence computing JD @ midnight UTC
        (ut / 24) +
        1721028.5 -
        2451545.0; // for J2000
  }
}

// http://www2.arnes.si/~gljsentvid10/sidereal.htm
//
// Shamelessly translated from
// https://github.com/codebox/star-rise-and-set-times/blob/master/calc.js
// class RiseSetTimes {
//   final DateTime? riseTime;
//   final DateTime? setTime;
//   final bool belowHorizon;
//   final bool circumpolar;

//   RiseSetTimes({
//     this.riseTime,
//     this.setTime,
//     this.belowHorizon = false,
//     this.circumpolar = false,
//   });

//   // factory _RiseSetTimes.fromMillisecondsSinceEpoch({
//   //   required num riseTimeMilliseconds,
//   //   required num setTimeMilliseconds,
//   //   bool belowHorizon = false,
//   //   bool circumpolar = false,
//   // }) =>
//   //     _RiseSetTimes(
//   //         riseTime:
//   //             DateTime.fromMillisecondsSinceEpoch(riseTimeMilliseconds.round()),
//   //         setTime:
//   //             DateTime.fromMillisecondsSinceEpoch(setTimeMilliseconds.round()),
//   //         belowHorizon: belowHorizon,
//   //         circumpolar: circumpolar);

//   static const MINUTES_PER_HOUR = 60;
//   static const SECONDS_PER_HOUR = 60;
//   static const SECONDS_PER_MINUTE = 60;
//   static const HOURS_PER_DAY = 24;
//   static const MILLISECONDS_PER_SECOND = 1000;
//   static const MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;
//   static const SECONDS_PER_DAY = SECONDS_PER_MINUTE * MINUTES_PER_DAY;
//   static const MILLISECONDS_PER_DAY = SECONDS_PER_DAY * MILLISECONDS_PER_SECOND;
//   static const EPOCH_MILLIS_AT_2000_01_01_12_00_00 = 946728000000;

//   /// Convert [timeInHours] to a DateTime object
//   static TimeOfDay hoursToClockTime(num timeInHours) {
//     final hours = timeInHours.floor();
//     final minutes = ((timeInHours - hours) * MINUTES_PER_HOUR).floor();
//     // final seconds = ((timeInHours - hours - minutes / MINUTES_PER_HOUR) * SECONDS_PER_HOUR).floor();

//     return TimeOfDay(hour: hours, minute: minutes);
//   }

//   /// find all `n` such that
//   /// `x_0 <= (n * m + r - a) / b <= x_1`
//   static List<num> unmod(num r, num a, num b, num m, num x_0, num x_1) {
//     // find all 'n' such that x_0 <= (n * m + r - a) / b <= x_1
//     final fromN = ((x_0 * b + a - r) / m).ceil();
//     final toN = ((x_1 * b + a - r) / m).floor();
//     final xValues = <num>[];
//     for (var n = fromN; n <= toN; n++) {
//       xValues.add((n * m + r - a) / b);
//     }
//     return xValues;
//   }

//   static TimeOfDay radiansToUtcTime(
//       double radians, gps.LocationData userLocation) {
//     final daysSince_2000_01_01_12 = (DateTime.now().millisecondsSinceEpoch -
//             EPOCH_MILLIS_AT_2000_01_01_12_00_00) /
//         MILLISECONDS_PER_DAY;
//     final prevMidDay = (daysSince_2000_01_01_12).floor();
//     // https://aa.usno.navy.mil/faq/docs/GAST.php
//     final days = unmod(radians, 4.894961212735792 + (userLocation.latRadian!),
//         6.30038809898489, 2 * pi, prevMidDay, prevMidDay + 1)[0];
//     final millisSinceEpoch =
//         days * MILLISECONDS_PER_DAY + EPOCH_MILLIS_AT_2000_01_01_12_00_00;
//     final millisSinceStartOfDay = millisSinceEpoch % MILLISECONDS_PER_DAY;
//     final hoursSinceStartOfDay =
//         millisSinceStartOfDay / (MILLISECONDS_PER_SECOND * SECONDS_PER_HOUR);
//     return hoursToClockTime(hoursSinceStartOfDay);
//   }

//   factory RiseSetTimes.forObject(
//       RightAscession ra, Declination dec, gps.LocationData location) {
//     if ((dec.degree - location.latitude!).abs() >= 90)
//       return RiseSetTimes(belowHorizon: true);
//     if ((dec.degree + location.latitude!).abs() >= 90)
//       return RiseSetTimes(circumpolar: true);

//     final c = acos(-tan(dec.radian) * tan(location.latRadian!));
//     final riseTimeRadians = ra.radian - c;
//     final setTimeRadians = ra.radian + c;

//     return RiseSetTimes(
//       riseTime: radiansToUtcTime(riseTimeRadians, location).toDateTimeUTC(),
//       setTime: radiansToUtcTime(setTimeRadians, location).toDateTimeUTC(),
//     );
//   }
// }

// extension on TimeOfDay {
//   /// Convert to [DateTime] in local timezone
//   DateTime toDateTimeUTC() {
//     final now = DateTime.now().toUtc();
//     return DateTime(
//       now.year,
//       now.month,
//       now.day,
//       this.hour,
//       this.minute,
//     ); // always in local timezone
//   }
// }
