import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart' as gps;

// enum Difficulty { VeryEasy, Easy, Moderate, Hard }

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
        h * 15,
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

/// Page to display the observations as a gallery
class ListOfObjects extends StatelessWidget {
  const ListOfObjects({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: "List of Messier Objects");
    // print("Test: ${DateTime.utc(1994, 6, 16, 18).JulianDay}"); // must be -2024.75
    return FutureBuilder<gps.LocationData?>(
      future: _getLocation(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Column(children: [
            CircularProgressIndicator(),
            Text("Getting current GPS location...")
          ]);
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
              return Column(children: [
                CircularProgressIndicator(),
                Text("Loading Messier data...")
              ]);
            return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection("users/" +
                      FirebaseAuth.instance.currentUser!.uid +
                      "/observations")
                  // .where("messier", isGreaterThan: 0)
                  .get(GetOptions(source: Source.cache)),
              builder: (context, snap3) =>
                  snap3.connectionState != ConnectionState.done
                      ? Column(children: [
                          CircularProgressIndicator(),
                          Text("Loading viewed data...")
                        ])
                      : ListView.builder(
                          itemCount: snap2.data?.size,
                          itemBuilder: (context, index) => Messier.fromJSON(
                            snap.data,
                            snap2.data!.docs[index].data(),
                            snap3.data!.docs
                                .where((element) =>
                                    snap2.data!.docs[index].data()['number'] ==
                                    element.data()["messier"])
                                .isNotEmpty,
                          ),
                        ),
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
