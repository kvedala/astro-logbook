import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import 'objects.dart';

/// Define a Right Ascession object
class RightAscession {
  final int _hour;
  final double _minute;

  RightAscession(this._hour, this._minute);
  factory RightAscession.fromJSON(Map<String, num> json) =>
      RightAscession(json["hour"] as int, json["minute"] as double);

  double get degree => (_hour * 15) + (_minute * 15) / 60;
  double get radian => degree * pi / 180.0;

  Map<String, num> get json => {"hour": _hour, "minute": _minute};
}

/// Define a Declination object
class Declination {
  final int _deg;
  final double _minute;
  final String sign;

  Declination(this._deg, this._minute, this.sign);
  factory Declination.fromJSON(Map<String, num> json) => Declination(
      json["degree"] as int, json["minute"] as double, json["sign"] as String);

  double get degree => (_deg) + (_minute) / 60;
  double get radian => degree * pi / 180.0;

  Map<String, num> get json => {"degree": _deg, "minute": _minute};
}

Future<QuerySnapshot<Map<String, dynamic>>> uploadMessier() async {
  final data = await rootBundle.loadString("assets/messier.csv");

  var out1 = CsvToListConverter().convert(data);
  out1.removeAt(0);
  final out2 = out1.map<Messier>((item) {
    final ra = item[4] as String;
    String dec = item[5] as String;
    String sign = '+';
    if (dec[0] == '-') {
      sign = '1';
      dec = dec.substring(1);
    }

    int splitIndexRA = ra.indexOf("h ");
    int splitIndexDEC = dec.indexOf("°");

    return Messier(
      int.parse((item[0] as String).substring(1)),
      item[2] as String,
      RightAscession(
        int.parse(ra.substring(0, splitIndexRA)),
        double.parse(ra.substring(splitIndexRA + 2, ra.length - 1)),
      ),
      Declination(int.parse(dec.substring(0, splitIndexDEC)),
          double.parse(dec.substring(splitIndexDEC + 1)), sign),
      difficulty: item[10],
    );
  }).toList(growable: false);

  for (final element in out2)
    await FirebaseFirestore.instance
        .collection("messier")
        .doc("${element.id}")
        .set(element.json);

  return FirebaseFirestore.instance.collection("/messier").orderBy("mid").get();
}

Future<QuerySnapshot<Map<String, dynamic>>> saveNGCObjects() async {
  final data = await rootBundle.loadString("assets/NGCObjects.csv");

  var out1 = CsvToListConverter().convert(data);
  out1.removeAt(0);
  final out2 = out1.map<NGC>((item) {
    return NGC(
      item[0],
      item[2] as String,
      RightAscession(
        int.parse(item[6] as String),
        double.parse(item[7] as String),
      ),
      Declination(
        int.parse(item[9] as String),
        double.parse(item[10] as String),
        item[8],
      ),
      magnitude:
          item[4].runtimeType == String ? num.tryParse(item[4]) : item[4],
    );
  }).toList(growable: false);

  for (final element in out2)
    await FirebaseFirestore.instance
        .collection("ngc")
        .doc("${element.id}")
        .set(element.json);

  return FirebaseFirestore.instance.collection("/ngc").orderBy("ngc").get();
}
