import 'package:astro_log/add_observation.dart';
import 'package:astro_log/equipment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'utils.dart';

/// Tracks the gallery tiles that are currently selected
List<DocumentReference> selectedTiles = [];

/// Widget to display tile in the gallery view
class GallaryTile extends StatefulWidget {
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
  final num seeing;

  /// Sky visibility at the time of observation
  final num visibility;

  /// Sky transparency at the time of observation
  final num transparency;

  /// [Equipment] details
  final Equipment equipment;

  /// dB document reference
  final DocumentReference reference;

  /// Widget to display tile in the gallery view
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
    this.transparency,
    this.notes,
    this.location,
    this.equipment,
    this.reference,
  });

  /// Generate a gallery tile using data from [ObservationData] object.
  GallaryTile.fromObservation(ObservationData data, {this.reference})
      : title = data.title,
        filePath = data.fileName,
        image = null,
        time = data.dateTime,
        messier = data.messier,
        ngc = data.ngc,
        seeing = data.seeing,
        visibility = data.visibility,
        transparency = data.transparency,
        notes = data.notes,
        latitude = data.latitude,
        longitude = data.longitude,
        location = data.location,
        equipment = data.equipment;

  _GallaryTileState createState() => _GallaryTileState();

  // final Map<String, dynamic> state = {'isChecked': false};
}

class _GallaryTileState extends State<GallaryTile> {
  bool get isSelected => selectedTiles.any((ref) => ref == widget.reference);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(15),
        color: isSelected ? Colors.red.withAlpha(80) : null,
      ),
      child: InkWell(
        child: GridTile(
          // header: Checkbox(
          //     value: checked,
          //     onChanged: (val) => setState(() => checked = val)),
          // footer: Text(time.toString()),

          child: SingleChildScrollView(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(fontSize: 20),
                ),
                widget.messier == null
                    ? SizedBox()
                    : Text(
                        "Messier# ${widget.messier}",
                        style: TextStyle(fontSize: 15),
                      ),
                widget.ngc == null
                    ? SizedBox()
                    : Text(
                        "NGC# ${widget.ngc}",
                        style: TextStyle(fontSize: 15),
                      ),
                Text(
                  "Observation Date: " +
                      widget.time.yMMMd +
                      " " +
                      widget.time.hourMinute,
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        onTap: () async {
          final List<String> originalNotes = List.from(widget.notes);
          await Navigator.push(context,
              MaterialPageRoute(builder: (context) => _ShowDetails(widget)));
          if (!UnorderedIterableEquality<String>()
              .equals(originalNotes, widget.notes)) {
            widget.reference.update({'notes': widget.notes});
            debugPrint("${widget.reference.path}: Updating the DB notes.");
          } else
            debugPrint("${widget.reference.path}: NOT Updating the DB notes.");
        },
        onLongPress: () {
          setState(() => isSelected
              ? selectedTiles.remove(widget.reference)
              : selectedTiles.add(widget.reference));
        },
      ),
    );
  }
}

/// Page to display the details of observation
class _ShowDetails extends StatefulWidget {
  /// [GallaryTile] to show details of
  final GallaryTile tile;

  /// convenient lookup table to display as table rows
  final Map<String, dynamic> tableItems;

  _ShowDetails(this.tile)
      : tableItems = {
          'Messier': tile.messier == null ? "-" : tile.messier.toString(),
          'NGC': tile.ngc == null ? "-" : tile.ngc.toString(),
          'Date & Time': tile.time.yMMMd + " " + tile.time.hourMinute,
          'Seeing':
              tile.seeing == null ? "Unknown" : tile.seeing.toInt().toString(),
          'Visibility': tile.visibility == null
              ? "Unknown"
              : tile.visibility.toInt().toString(),
          'Transparency': tile.transparency == null
              ? "Unknown"
              : tile.transparency.toInt().toString(),
          'Location': tile.location,
          'Latitude': decimalDegreesToDMS(tile.latitude, 'lat'),
          'Longitude': decimalDegreesToDMS(tile.longitude, 'long'),
        };

  _ShowDetailsState createState() => _ShowDetailsState();
}

class _ShowDetailsState extends State<_ShowDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tile.title),
        centerTitle: true,
      ),
      body: Column(children: [
        Expanded(
          child: Column(children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Table(
                columnWidths: {0: FixedColumnWidth(120)},
                children: widget.tableItems.entries
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
            ),
            Container(
              padding: EdgeInsets.all(5),
              child: widget.tile.equipment == null
                  ? SizedBox()
                  : widget.tile.equipment,
            ),
            Container(
              padding: EdgeInsets.all(5),
              child: Row(
                children: [
                  Text("Notes:", style: TextStyle(fontSize: 20)),
                  IconButton(
                      icon: Icon(Icons.add_box_rounded), onPressed: _addNote)
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.tile.notes.length,
                itemBuilder: (context, index) => Dismissible(
                  key: Key(widget.tile.notes[index]),
                  background: Container(color: Colors.red.shade700),
                  child: ListTile(
                    leading: Text("${index + 1}"),
                    title: Text(widget.tile.notes[index]),
                    onTap: () => _editNote(context, index),
                  ),
                  confirmDismiss: (dir) => confirmDeleteTile(context),
                  onDismissed: (dir) => widget.tile.notes.removeAt(index),
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 5),
          child: ButtonBar(
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.close_rounded),
                label: Text("Close details"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.delete_forever_rounded),
                label: Text("Delete observation"),
                onPressed: () async => await confirmDeleteTile(context)
                    ? _deleteObservation(context)
                    : null,
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void _addNote() async {
    final textController = TextEditingController();
    bool response = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add note"),
        content: Container(
          child: TextField(
            controller: textController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 5,
            minLines: 2,
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: Icon(Icons.done),
            label: Text("Ok"),
            onPressed: () => Navigator.pop(context, true),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.cancel),
            label: Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );

    if (response) setState(() => widget.tile.notes.add(textController.text));
  }

  void _editNote(BuildContext context, int index) async {
    final textController =
        TextEditingController(text: widget.tile.notes[index]);
    bool response = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit note"),
        content: Container(
          child: TextField(
            controller: textController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 5,
            minLines: 2,
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: Icon(Icons.done),
            label: Text("Ok"),
            onPressed: () => Navigator.pop(context, true),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.cancel),
            label: Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );

    if (response)
      setState(() => widget.tile.notes[index] = textController.text);
  }

  void _deleteObservation(BuildContext context) async {
    final store = FirebaseFirestore.instance;
    final collectionPath =
        'users/' + FirebaseAuth.instance.currentUser.uid + '/observations/';
    final result = await store
        .collection(collectionPath)
        .where('title', isEqualTo: widget.tile.title)
        .where('dateTime', isEqualTo: widget.tile.time)
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
