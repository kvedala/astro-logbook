import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as gps;

import 'ra_dec.dart';
import 'rise_times.dart';

/// Generic Celestial object catalog
///
/// TODO: Optimize JSON serialization using automatic code generation: https://pub.dev/packages/json_serializable
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

  /// computed Rise & set times of the object
  final RiseSetTimes? riseTimes;

  Catalog(this.id, this.ra, this.dec,
      {super.key,
      required this.name,
      this.difficulty,
      this.type = "",
      this.magnitude,
      this.viewed = false,
      gps.LocationData? currentLocation})
      : riseTimes = currentLocation == null
            ? null
            : RiseSetTimes.forObject(ra, dec, currentLocation);

  // Catalog fromJSON(Map<String, dynamic> json, String name,
  //         [bool viewed = false, gps.LocationData? currentLocation]) =>
  //     Catalog(
  //       json['number'],
  //       RightAscession.fromJSON(json['ra']['degree']),
  //       Declination.fromJSON(json['dec']['degree']),
  //       name: name,
  //       type: json['type'],
  //       difficulty: json['difficulty'],
  //       viewed: viewed,
  //       currentLocation: currentLocation,
  //     );

  /// Export to JSON format Map
  Map<String, dynamic> get json => {
        "number": id,
        "catalog": name,
        "type": type,
        "ra": ra.json,
        "dec": dec.json,
        "viewed": viewed,
        "difficulty": difficulty,
      };

  @override
  Widget build(BuildContext context) {
    late Widget visible;
    if (riseTimes == null) {
      visible = const SizedBox();
    } else if (riseTimes!.belowHorizon) {
      visible = Icon(Icons.cancel, color: Colors.red[900]);
    } else if (riseTimes!.circumpolar ||
        riseTimes!.riseTime!.hour >= 18 ||
        riseTimes!.setTime!.hour <= 5) {
      visible = Icon(Icons.done, color: Colors.green[900]);
    } else {
      visible = Icon(Icons.cancel, color: Colors.red[900]);
    }
    return ListTile(
      visualDensity: VisualDensity.comfortable,
      dense: true,
      leading: Column(children: [
        Text("M $id"),
        Icon(
          viewed ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: viewed ? Colors.green[900] : Colors.red[900],
        ),
      ]),
      subtitle: Table(columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(.75),
        2: FlexColumnWidth(.5),
      }, children: [
        TableRow(children: [
          Text("RA: ${ra.toString()}"),
          Text(type),
          riseTimes == null
              ? const SizedBox()
              : riseTimes!.circumpolar
                  ? const Text("Circumpolar")
                  : riseTimes!.belowHorizon
                      ? const Text("Below Horizon")
                      : Text(
                          "Rise: ${DateFormat("HH:mm").format(riseTimes!.riseTime!)}"),
        ]),
        TableRow(children: [
          Text("DEC: ${dec.toString()}"),
          Text(difficulty ?? ""),
          riseTimes == null
              ? const SizedBox()
              : (riseTimes!.circumpolar | riseTimes!.belowHorizon)
                  ? const SizedBox()
                  : Text(
                      "Set: ${DateFormat("HH:mm").format(riseTimes!.setTime!)}"),
        ]),
      ]),
      trailing: visible,
      // onLongPress: () => Navigator.push(context,
      //     MaterialPageRoute(builder: (context) => ViewObjectInfo(name, id))),
    );
  }
}

/// Convenience class to store Messier Objects.
/// Displays as a list tile.
class Messier extends Catalog {
  Messier(int id, String type, RightAscession ra, Declination dec,
      {super.key,
      String? difficulty,
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
}

/// Convenience class to store NGC Objects.
/// Displays as a list tile.
class NGC extends Catalog {
  NGC(int id, String type, RightAscession ra, Declination dec,
      {super.key,
      String? difficulty,
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
}

/// Convenience class to store Caldwell Objects.
/// Displays as a list tile.
class Caldwell extends Catalog {
  Caldwell(int id, String type, RightAscession ra, Declination dec,
      {super.key,
      String? difficulty,
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
}
