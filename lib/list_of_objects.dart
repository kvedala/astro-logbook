import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

enum Difficulty { VeryEasy, Easy, Moderate, Hard }

class Coordinate {
  final int hour;
  final num minute;
  Coordinate(this.hour, this.minute);

  factory Coordinate.fromHourMin(String text) {
    final splitIndex = text.indexOf("h ");
    final L = text.length;
    return Coordinate(
      int.parse(text.substring(0, splitIndex)),
      num.parse(text.substring(splitIndex + 2, L - 1)),
    );
  }

  factory Coordinate.fromDegMin(String text) {
    final splitIndex = text.indexOf("°");
    return Coordinate(
      int.parse(text.substring(0, splitIndex)),
      num.parse(text.substring(splitIndex + 1)),
    );
  }

  @override
  String toString() => "${hour}h ${minute}m";

  Map<String, num> toJSON() => {"hour": hour, "minute": minute};
}

class Messier extends StatelessWidget {
  final int mid;
  final int? ngc;
  final String type;
  final Coordinate ra;
  final Coordinate dec;
  final String? difficulty;

  Messier(this.mid, this.type, this.ra, this.dec, {this.ngc, this.difficulty});

  factory Messier.fromJSON(Map<String, dynamic> json) {
    return Messier(
      json['mid'],
      json['type'],
      Coordinate(json['ra']['hour'], json['ra']['minute']),
      Coordinate(json['dec']['hour'], json['dec']['minute']),
      ngc: json['ngc'],
      difficulty: json['difficulty'],
    );
  }

  Map<String, dynamic> getData() => {
        "mid": mid,
        "ngc": ngc,
        "type": type,
        "ra": ra.toJSON(),
        "dec": dec.toJSON(),
        "difficulty": difficulty.toString()
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      dense: true,
      leading: Text("$mid"),
      subtitle: Table(children: [
        TableRow(children: [
          Text("RA: ${ra.toString()}"),
          Text(type),
        ]),
        TableRow(children: [
          Text("DEC: ${dec.toString()}"),
          Text(difficulty ?? ""),
        ]),
      ]),
    );
  }
}

/// Page to display the observations as a gallery
class ListOfObjects extends StatelessWidget {
  const ListOfObjects({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: "List of Objects");
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // future: _readObjects(),
      future: FirebaseFirestore.instance
          .collection("/messier")
          .orderBy("mid")
          .get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (snap.data == null) return Center(child: Text("No data!"));
        return ListView.builder(
          itemCount: snap.data?.size,
          itemBuilder: (context, index) =>
              Messier.fromJSON(snap.data!.docs[index].data()),
        );
      },
    );
  }

  // ignore: unused_element
  Future<QuerySnapshot<Map<String, dynamic>>> _readObjects() async {
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
          .doc("${element.mid}")
          .set(element.getData());

    return FirebaseFirestore.instance.collection("/messier").get();
  }
}
