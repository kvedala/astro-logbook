import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as gps;

import 'generated/l10n.dart';
import 'ra_dec.dart';
import 'rise_times.dart';
import 'wikipedia_page.dart';

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

  /// apparent magnitude of the object
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
        if (magnitude != null) "magnitude": magnitude,
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
      // Highlight targets that are up during the evening/night observing window.
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
      title: this is Messier && (this as Messier).ngcNumbers.isNotEmpty
          ? Text('Related: ${(this as Messier).ngcNumbers.map((n) => 'NGC $n').join(', ')}')
          : null,
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
                  ? Text(S.current.circumpolar)
                  : riseTimes!.belowHorizon
                      ? Text(S.current.belowHorizon)
                      : Text(
                          "${S.current.rise}: ${DateFormat("HH:mm").format(riseTimes!.riseTime!)}"),
        ]),
        TableRow(children: [
          Text("DEC: ${dec.toString()}"),
          Text([
            ?difficulty,
            if (magnitude != null) 'Mag $magnitude',
          ].join(' · ')),
          riseTimes == null
              ? const SizedBox()
              : (riseTimes!.circumpolar | riseTimes!.belowHorizon)
                  ? const SizedBox()
                  : Text(
                      "${S.current.set}: ${DateFormat("HH:mm").format(riseTimes!.setTime!)}"),
        ]),
      ]),
      trailing: visible,
      onTap: name == 'Messier' ? () => openMessierWikipedia(context, id) : null,
      // onLongPress: () => Navigator.push(context,
      //     MaterialPageRoute(builder: (context) => ViewObjectInfo(name, id))),
    );
  }
}

/// Convenience class to store Messier Objects.
/// Displays as a list tile.
class Messier extends Catalog {
  final String? designation;
  final String? constellation;
  final String? size;
  final int? distanceLightYears;
  final String? viewingSeason;
  final List<int> ngcNumbers;

  Messier(super.id, String type, super.ra, super.dec,
      {super.key,
      super.difficulty,
      super.magnitude,
      super.viewed,
      super.currentLocation,
      this.designation,
      this.constellation,
      this.size,
      this.distanceLightYears,
      this.viewingSeason,
      this.ngcNumbers = const []})
      : super(name: "Messier", type: type);

  @override
  Map<String, dynamic> get json => {
        ...super.json,
        if (designation != null) 'designation': designation,
        if (constellation != null) 'constellation': constellation,
        if (size != null) 'size': size,
        if (distanceLightYears != null) 'distanceLightYears': distanceLightYears,
        if (viewingSeason != null) 'viewingSeason': viewingSeason,
        if (ngcNumbers.isNotEmpty) 'ngcNumbers': ngcNumbers,
      };

  factory Messier.fromJSON(Map<String, dynamic> json,
      [bool viewed = false, gps.LocationData? currentLocation]) {
    return Messier(
      json['number'],
      json['type'],
      RightAscession.fromJSON(json['ra']),
      Declination.fromJSON(json['dec']),
      difficulty: json['difficulty'],
      magnitude: json['magnitude'] as num?,
      designation: json['designation'] as String?,
      constellation: json['constellation'] as String?,
      size: json['size'] as String?,
      distanceLightYears: json['distanceLightYears'] as int?,
      viewingSeason: json['viewingSeason'] as String?,
      ngcNumbers: (json['ngcNumbers'] as List<dynamic>? ?? []).cast<int>(),
      viewed: viewed,
      currentLocation: currentLocation,
    );
  }
}

/// Convenience class to store NGC Objects.
/// Displays as a list tile.
class NGC extends Catalog {
  final String? designation;
  final String? constellation;
  final String? info;

  NGC(super.id, String type, super.ra, super.dec,
      {super.key,
      super.difficulty,
      super.magnitude,
      super.viewed,
      super.currentLocation,
      this.designation,
      this.constellation,
      this.info})
      : super(name: "NGC", type: type);

  @override
  Map<String, dynamic> get json => {
        ...super.json,
        if (designation != null) 'designation': designation,
        if (constellation != null) 'constellation': constellation,
        if (info != null) 'info': info,
      };

  factory NGC.fromJSON(Map<String, dynamic> json,
      [bool viewed = false, gps.LocationData? currentLocation]) {
    return NGC(
      json['number'],
      json['type'],
      RightAscession.fromJSON(json['ra']),
      Declination.fromJSON(json['dec']),
      difficulty: json['difficulty'],
      magnitude: json['magnitude'] as num?,
      designation: json['designation'] as String?,
      constellation: json['constellation'] as String?,
      info: json['info'] as String?,
      viewed: viewed,
      currentLocation: currentLocation,
    );
  }
}

/// Convenience class to store Caldwell Objects.
/// Displays as a list tile.
class Caldwell extends Catalog {
  Caldwell(super.id, String type, super.ra, super.dec,
      {super.key,
      super.difficulty,
      super.magnitude,
      super.viewed,
      super.currentLocation})
      : super(name: "Caldwell", type: type);

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
