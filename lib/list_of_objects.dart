import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as gps;

enum Difficulty { VeryEasy, Easy, Moderate, Hard }

/// Convenience class to store hours and minutes of a coordinate
class Coordinate {
  final double value;
  final bool isNegative;

  // final int hour;
  // final num minute;
  // final num second;
  Coordinate(this.value) : isNegative = value < 0;

  factory Coordinate.fromHMS(int hour, num minute,
          [num second = 0, bool isNegative = false]) =>
      isNegative && hour >= 0
          ? Coordinate(-1 * (hour + (minute + second / 60) / 60))
          : Coordinate(hour + (minute + second / 60) / 60);

  int get hour => value.floor();
  int get minute => ((value - hour) * 60).floor();
  double get second => ((value - hour) * 60 - minute) * 60;

  /// Create from a text string of type:
  /// 4h 3.4m
  factory Coordinate.fromHourMin(String text) {
    final splitIndex = text.indexOf("h ");
    final L = text.length;
    final h = int.parse(text.substring(0, splitIndex));
    return Coordinate.fromHMS(
        h,
        num.parse(text.substring(splitIndex + 2, L - 1)),
        0,
        text[0] == '-' ? true : false);
  }

  /// Create from a text string of type:
  /// 4°3.4
  factory Coordinate.fromDegMin(String text) {
    final splitIndex = text.indexOf("°");
    final h = int.parse(text.substring(0, splitIndex));
    return Coordinate.fromHMS(
      h,
      num.parse(text.substring(splitIndex + 1)),
      0,
      text[0] == '-' ? true : false,
    );
  }

  @override
  String toString() =>
      "${isNegative ? "-" : ""}${hour.abs()}h ${minute}m ${second.toStringAsPrecision(2)}s";

  /// Export to a JSON map
  Map<String, num> get json => {"degree": degree};

  /// Get coordinate in radian
  num get radian => this.value * pi / 180;

  /// Get coordinate in degree
  num get degree => value; //(hour + (minute + (second / 60)) / 60);
}

extension on TimeOfDay {
  /// Convert to [DateTime] in local timezone
  DateTime toDateTimeUTC() {
    final now = DateTime.now().toUtc();
    return DateTime(
      now.year,
      now.month,
      now.day,
      this.hour,
      this.minute,
    ); // always in local timezone
  }
}

extension on gps.LocationData {
  double? get latitudeRad => this.latitude! * pi / 180;
  double? get longitudeRad => this.longitude! * pi / 180;
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
      Coordinate ra, Coordinate dec, gps.LocationData location) {
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

/// Convenience class to store Messier Objects.
/// Displays as a list tile.
class Messier extends StatelessWidget {
  final int id;
  // final int? ngc;
  final String type;
  final Coordinate ra;
  final Coordinate dec;
  final String? difficulty;
  final num? magnitude;
  final gps.LocationData? location;

  Messier(this.id, this.type, this.ra, this.dec,
      {this.difficulty, this.location, this.magnitude});

  factory Messier.fromJSON(
    gps.LocationData? location,
    Map<String, dynamic> json,
  ) {
    return Messier(
      json['number'],
      json['type'],
      Coordinate(json['ra']['degree']),
      Coordinate(json['dec']['degree']),
      difficulty: json['difficulty'],
      location: location,
    );
  }

  /// Export to JSON format Map
  Map<String, dynamic> toJSON() => {
        "number": id,
        "type": type,
        "ra": ra.json,
        "dec": dec.json,
        "difficulty": difficulty.toString()
      };

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
      leading: Text("$id"),
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

  _RiseSetTimes? getRiseAndSetTime() {
    if (location == null) return null;
    return _RiseSetTimes.forObject(ra, dec, location!);
  }
}

/// Page to display the observations as a gallery
class ListOfObjects extends StatelessWidget {
  const ListOfObjects({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: "List of Objects");
    // print("Test: ${DateTime.utc(1994, 6, 16, 18).JulianDay}"); // must be -2024.75
    return FutureBuilder<gps.LocationData?>(
      future: _getLocation(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (snap.data == null)
          return Center(
            child: Text("No GPS!\nCannot compute Rise and Set times."),
          );
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              // return _saveMessierObjects();
              FirebaseFirestore.instance
                  .collection("/messier")
                  .orderBy("number")
                  .snapshots(),
          builder: (ctx, snap2) {
            // if (snap2.connectionState != ConnectionState.done)
            //   return Center(child: CircularProgressIndicator());
            if (snap2.data == null)
              // return Center(child: Text("No Data!"));
              return Center(child: CircularProgressIndicator());
            return ListView.builder(
              itemCount: snap2.data?.size,
              itemBuilder: (context, index) =>
                  Messier.fromJSON(snap.data, snap2.data!.docs[index].data()),
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  static Future<QuerySnapshot<Map<String, dynamic>>>
      saveMessierObjects() async {
    final data = await rootBundle.loadString("assets/messier.csv");

    var out1 = CsvToListConverter().convert(data);
    out1.removeAt(0);
    final out2 = out1.map<Messier>((item) {
      return Messier(
        int.parse((item[0] as String).substring(1)),
        item[2] as String,
        Coordinate.fromHourMin(item[4]),
        Coordinate.fromDegMin(item[5]),
        difficulty: item[10],
      );
    }).toList(growable: false);

    for (final element in out2)
      await FirebaseFirestore.instance
          .collection("messier")
          .doc("${element.id}")
          .set(element.toJSON());

    return FirebaseFirestore.instance
        .collection("/messier")
        .orderBy("mid")
        .get();
  }

  // ignore: unused_element
  static Future<QuerySnapshot<Map<String, dynamic>>> saveNGCObjects() async {
    final data = await rootBundle.loadString("assets/NGCObjects.csv");

    var out1 = CsvToListConverter().convert(data);
    out1.removeAt(0);
    final out2 = out1.map<Messier>((item) {
      final decNegative = item[8] == '+' ? false : true;
      return Messier(
        item[0],
        item[2] as String,
        Coordinate.fromHMS(item[6], item[7]),
        Coordinate.fromHMS(item[9], item[10], 0, decNegative),
        magnitude:
            item[4].runtimeType == String ? num.tryParse(item[4]) : item[4],
      );
    }).toList(growable: false);

    for (final element in out2)
      await FirebaseFirestore.instance
          .collection("ngc")
          .doc("${element.id}")
          .set(element.toJSON());

    return FirebaseFirestore.instance.collection("/ngc").orderBy("ngc").get();
  }

  Future<gps.LocationData?> _getLocation() async {
    gps.Location location = new gps.Location();

    bool _serviceEnabled;
    gps.PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == gps.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != gps.PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }
}
