import 'package:astro_log/add_observation.dart';
import 'package:flutter/material.dart';

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
        header: Text(title),
        // footer: Text(time.toString()),
        child: Center(
          child: Text(title),
        ),
      ),
    );
  }
}
