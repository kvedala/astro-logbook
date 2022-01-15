import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as gps;

import 'ra_dec.dart';
import 'rise_times.dart';

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

  late final RiseSetTimes? riseTimes;

  Catalog(this.id, this.ra, this.dec,
      {required this.name,
      this.difficulty,
      this.type = "",
      this.magnitude,
      this.viewed = false,
      gps.LocationData? currentLocation}) {
    if (currentLocation == null)
      riseTimes = null;
    else {
      riseTimes = RiseSetTimes.forObject(ra, dec, currentLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    late Widget visible;
    if (riseTimes == null)
      visible = SizedBox();
    else if (riseTimes!.belowHorizon)
      visible = Icon(Icons.cancel);
    else if (riseTimes!.circumpolar ||
        riseTimes!.riseTime!.hour >= 18 ||
        riseTimes!.setTime!.hour <= 5) {
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
          riseTimes == null
              ? SizedBox()
              : riseTimes!.circumpolar
                  ? Text("Circumpolar")
                  : riseTimes!.belowHorizon
                      ? Text("Below Horizon")
                      : Text(
                          "Rise: ${DateFormat("HH:mm").format(riseTimes!.riseTime!)}"),
        ]),
        TableRow(children: [
          Text("DEC: ${dec.toString()}"),
          Text(difficulty ?? ""),
          riseTimes == null
              ? SizedBox()
              : (riseTimes!.circumpolar | riseTimes!.belowHorizon)
                  ? SizedBox()
                  : Text(
                      "Set: ${DateFormat("HH:mm").format(riseTimes!.setTime!)}"),
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
      {String? difficulty,
      num? magnitude,
      bool viewed = false,
      gps.LocationData? currentLocation})
      : super(id, ra, dec,
            name: "Messier",
            difficulty: difficulty,
            type: type,
            magnitude: magnitude,
            viewed: viewed,
            currentLocation: currentLocation);

  factory Messier.fromJSON(Map<String, dynamic> json,
      [bool viewed = false, gps.LocationData? currentLocation]) {
    return Messier(
      json['number'],
      json['type'],
      RightAscession.fromJSON(json['ra']),
      Declination.fromJSON(json['dec']),
      difficulty: json['difficulty'],
      viewed: viewed,
      currentLocation: currentLocation,
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
}

/// Convenience class to store NGC Objects.
/// Displays as a list tile.
class NGC extends Catalog {
  NGC(int id, String type, RightAscession ra, Declination dec,
      {String? difficulty,
      num? magnitude,
      bool viewed = false,
      gps.LocationData? currentLocation})
      : super(id, ra, dec,
            name: "NGC",
            difficulty: difficulty,
            type: type,
            magnitude: magnitude,
            viewed: viewed,
            currentLocation: currentLocation);

  factory NGC.fromJSON(Map<String, dynamic> json,
      [bool viewed = false, gps.LocationData? currentLocation]) {
    return NGC(
      json['number'],
      json['type'],
      RightAscession.fromJSON(json['ra']['degree']),
      Declination.fromJSON(json['dec']['degree']),
      difficulty: json['difficulty'],
      viewed: viewed,
      currentLocation: currentLocation,
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
}

/// Convenience class to store Caldwell Objects.
/// Displays as a list tile.
class Caldwell extends Catalog {
  Caldwell(int id, String type, RightAscession ra, Declination dec,
      {String? difficulty,
      num? magnitude,
      bool viewed = false,
      gps.LocationData? currentLocation})
      : super(id, ra, dec,
            name: "Caldwell",
            difficulty: difficulty,
            type: type,
            magnitude: magnitude,
            viewed: viewed,
            currentLocation: currentLocation);

  factory Caldwell.fromJSON(Map<String, dynamic> json,
      [bool viewed = false, gps.LocationData? currentLocation]) {
    return Caldwell(
      json['number'],
      json['type'],
      RightAscession.fromJSON(json['ra']['degree']),
      Declination.fromJSON(json['dec']['degree']),
      difficulty: json['difficulty'],
      viewed: viewed,
      currentLocation: currentLocation,
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
}
