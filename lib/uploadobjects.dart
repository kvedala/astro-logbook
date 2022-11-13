import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import 'objects.dart';
import 'ra_dec.dart';

Future<QuerySnapshot<Map<String, dynamic>>> uploadMessier() async {
  final data = await rootBundle.loadString("assets/messier.csv");

  var out1 = const CsvToListConverter().convert(data);
  out1.removeAt(0);
  final out2 = out1.map<Messier>((item) {
    final ra = item[4] as String;
    String dec = item[5] as String;
    String sign = '+';
    if (dec[0] == '-') {
      sign = '-';
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

  for (final element in out2) {
    var j = element.json;
    j.remove('viewed');
    j.remove('catalog');
    await FirebaseFirestore.instance
        .collection(element.name)
        .doc("${element.id}")
        .set(j);
  }
  return FirebaseFirestore.instance.collection("/messier").orderBy("mid").get();
}

Future<QuerySnapshot<Map<String, dynamic>>> uploadNGC() async {
  final data = await rootBundle.loadString("assets/NGCObjects.csv");

  var out1 = const CsvToListConverter().convert(data);
  out1.removeAt(0);
  final out2 = out1.map<NGC>((item) {
    return NGC(
      item[0],
      item[2] as String,
      RightAscession(
        item[6],
        item[7],
      ),
      Declination(
        item[9],
        item[10],
        item[8],
      ),
      magnitude:
          item[4].runtimeType == String ? num.tryParse(item[4]) : item[4],
    );
  }).toList(growable: false);

  for (final element in out2) {
    await FirebaseFirestore.instance
        .collection("ngc")
        .doc("${element.id}")
        .set(element.json);
  }

  return FirebaseFirestore.instance.collection("/ngc").orderBy("ngc").get();
}
