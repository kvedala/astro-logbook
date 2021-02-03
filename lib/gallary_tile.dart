import 'package:astro_log/add_observation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GallaryTile extends StatelessWidget {
  final String filePath;
  final String title;
  final Image image;
  final DateTime time;
  final int messier;
  final int ngc;
  final List<String> notes;
  final num latitude;
  final num longitude;
  final String location;

  GallaryTile(this.title,
      {this.filePath,
      this.image,
      this.time,
      this.latitude,
      this.longitude,
      this.messier,
      this.ngc,
      this.notes,
      this.location});

  GallaryTile.fromObservation(ObservationData data)
      : title = data.title,
        filePath = data.fileName,
        image = null,
        time = data.dateTime,
        messier = data.messier,
        ngc = data.ngc,
        notes = data.notes,
        latitude = data.latitude,
        longitude = data.longitude,
        location = data.location;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(15),
      ),
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
              ]),
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
    );
  }
}
