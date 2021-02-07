import 'package:astro_log/add_observation.dart';
import 'package:astro_log/equipment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget to display tile in the gallery view
class GallaryTile extends StatelessWidget {
  /// path of image file, if any
  final String filePath;

  /// title of the tile
  final String title;

  /// [Image] to display on the tile
  final Image image;

  /// Time of observation or image
  final DateTime time;

  /// Messier catalog number, if any
  final int messier;

  /// NGC catalog number, if any
  final int ngc;

  /// Notes taken for the observation/photograph
  final List<String> notes;

  /// Observation latitude
  final num latitude;

  /// Observation longitude
  final num longitude;

  /// Address of the location
  final String location;

  /// Sky seeing at the time of observation
  int seeing;

  /// Sky visibility at the time of observation
  int visibility;

  /// [Equipment] details
  final Equipment equipment;

  GallaryTile(
    this.title, {
    this.filePath,
    this.image,
    this.time,
    this.latitude,
    this.longitude,
    this.messier,
    this.ngc,
    this.seeing,
    this.visibility,
    this.notes,
    this.location,
    this.equipment,
  });

  /// Generate a gallery tile using data from [ObservationData] object.
  GallaryTile.fromObservation(ObservationData data)
      : title = data.title,
        filePath = data.fileName,
        image = null,
        time = data.dateTime,
        messier = data.messier,
        ngc = data.ngc,
        seeing = data.seeing,
        visibility = data.visibility,
        notes = data.notes,
        latitude = data.latitude,
        longitude = data.longitude,
        location = data.location,
        equipment = data.equipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        child: GridTile(
          // header: Text(title),
          // footer: Text(time.toString()),
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 20),
                ),
                messier == null
                    ? SizedBox()
                    : Text(
                        "Messier# $messier",
                        style: TextStyle(fontSize: 15),
                      ),
                ngc == null
                    ? SizedBox()
                    : Text(
                        "NGC# $ngc",
                        style: TextStyle(fontSize: 15),
                      ),
                Text(
                  "Observation Date: " +
                      DateFormat.yMMMd().format(time) +
                      " " +
                      DateFormat.Hm().format(time),
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => _ShowDetails(this))),
      ),
    );
  }
}

/// Page to display the details of observation
class _ShowDetails extends StatelessWidget {
  final GallaryTile tile;
  final Map<String, dynamic> tableItems;
  _ShowDetails(this.tile)
      : tableItems = {
          'Messier': tile.messier == null ? "-" : tile.messier.toString(),
          'NGC': tile.ngc == null ? "-" : tile.ngc.toString(),
          'Date & Time': DateFormat.yMMMd().format(tile.time) +
              " " +
              DateFormat.Hm().format(tile.time),
          'Seeing': tile.seeing ?? "Unknown",
          'Visibility': tile.visibility ?? "Unknown",
          'Location': tile.location,
          'Latitude': _decimalDegreesToDMS(tile.latitude, 'lat'),
          'Longitude': _decimalDegreesToDMS(tile.longitude, 'long'),
        };

  static String _decimalDegreesToDMS(num numeric, String latOrLong) {
    bool isNegative = false;
    if (numeric < 0) {
      isNegative = true;
      numeric = -numeric;
    }
    int degree = numeric.floor();
    int minute = ((numeric - degree) * 60).floor();
    double seconds = (((numeric - degree) * 60) - minute) * 60;

    return "$degree\xb0 $minute\' ${seconds.toStringAsFixed(1)}\" " +
        (latOrLong == 'lat'
            ? (isNegative ? "S" : "N")
            : (isNegative ? "W" : "E"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tile.title),
        centerTitle: true,
      ),
      body: Column(children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(10),
          child: Column(children: [
            Table(
              columnWidths: {0: FixedColumnWidth(120)},
              children: tableItems.entries
                  .map(
                    (e) => TableRow(
                      children: e == null
                          ? []
                          : [
                              TableCell(
                                child: SizedBox(
                                  child: Text(e.key,
                                      style: TextStyle(fontSize: 18)),
                                  height: 25,
                                ),
                              ),
                              Text(e.value, style: TextStyle(fontSize: 18)),
                            ],
                    ),
                  )
                  .toList(),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: tile.equipment == null ? SizedBox() : tile.equipment,
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Text("Notes:", style: TextStyle(fontSize: 20)),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: tile.notes.length,
              itemBuilder: (context, index) => ListTile(
                leading: Text("${index + 1}"),
                title: Text(tile.notes[index]),
              ),
            )
          ]),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.delete_forever_rounded),
          label: Text("Delete observation"),
          onPressed: () => _deleteObservation(context),
        ),
      ]),
    );
  }

  void _deleteObservation(BuildContext context) async {
    final store = FirebaseFirestore.instance;
    final collectionPath =
        'users/' + FirebaseAuth.instance.currentUser.uid + '/observations/';
    final result = await store
        .collection(collectionPath)
        .where('title', isEqualTo: tile.title)
        .where('dateTime', isEqualTo: tile.time)
        .get();
    if (result.size != 1) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
                title: Text("Unable to delete the object."),
              ));
      return await Future.delayed(
          Duration(seconds: 1), () => Navigator.pop(context));
    }
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
              child: CircularProgressIndicator(),
            ));
    await store.doc(collectionPath + result.docs[0].id).delete();
    Navigator.pop(context);
    Navigator.pop(context);
    return;
  }
}
