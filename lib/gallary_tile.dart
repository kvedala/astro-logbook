import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'confirm_dialog.dart';
import 'generated/l10n.dart';
import 'utils.dart';
import 'equipment.dart';
import 'add_observation.dart';

/// Tracks the gallery tiles that are currently selected
List<DocumentReference?> selectedTiles = [];

/// Widget to display tile in the gallery view
///
/// TODO: Optimize JSON serialization using automatic code generation: https://pub.dev/packages/json_serializable
class GallaryTile extends StatefulWidget {
  /// path of image file, if any
  final String? filePath;

  /// title of the tile
  final String? title;

  /// [Image] to display on the tile
  final Image? image;

  /// Time of observation or image
  final DateTime? time;

  /// Messier catalog number, if any
  final int? messier;

  /// NGC catalog number, if any
  final int? ngc;

  /// Notes taken for the observation/photograph
  final List<String>? notes;

  /// Observation latitude
  final num? latitude;

  /// Observation longitude
  final num? longitude;

  /// Address of the location
  final String? location;

  /// Sky seeing at the time of observation
  final num? seeing;

  /// Sky visibility at the time of observation
  final num? visibility;

  /// Sky transparency at the time of observation
  final num? transparency;

  /// [Equipment] details
  final Equipment? equipment;

  /// dB document reference
  final DocumentReference? reference;

  /// Widget to display tile in the gallery view
  const GallaryTile(
    this.title, {
    super.key,
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
  GallaryTile.fromObservation(ObservationData data, {Key? key, this.reference})
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
        equipment = data.equipment,
        super(key: key);

  @override
  State<GallaryTile> createState() => _GallaryTileState();

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
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  widget.title!,
                  style: const TextStyle(fontSize: 20),
                ),
                widget.messier == null
                    ? const SizedBox()
                    : Text(
                        "${S.of(context).messierNumber} ${widget.messier}",
                        style: const TextStyle(fontSize: 15),
                      ),
                widget.ngc == null
                    ? const SizedBox()
                    : Text(
                        "${S.of(context).ngcNumber} ${widget.ngc}",
                        style: const TextStyle(fontSize: 15),
                      ),
                Text(
                  "${S.of(context).observationDate} ${widget.time!.yMMMd} ${widget.time!.hourMinute} (${widget.time!.timeZoneName})",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        onTap: () async {
          final List<String> originalNotes = List.from(widget.notes!);
          await Navigator.push(context,
              MaterialPageRoute(builder: (context) => _ShowDetails(widget)));
          if (!const UnorderedIterableEquality<String>()
              .equals(originalNotes, widget.notes)) {
            widget.reference!.update({'notes': widget.notes});
            debugPrint("${widget.reference!.path}: Updating the DB notes.");
          } else {
            debugPrint("${widget.reference!.path}: NOT Updating the DB notes.");
          }
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
          'Messier': TextEditingController(
              text: tile.messier == null ? "-" : tile.messier.toString()),
          'NGC': TextEditingController(
              text: tile.ngc == null ? "-" : tile.ngc.toString()),
          'Date & Time': TextEditingController(
              text:
                  "${tile.time!.yMMMd} ${tile.time!.hourMinute} (${tile.time!.timeZoneName})"),
          'Seeing':
              tile.seeing == null ? "Unknown" : tile.seeing!.toInt().toString(),
          'Visibility': tile.visibility == null
              ? "Unknown"
              : tile.visibility!.toInt().toString(),
          'Transparency': tile.transparency == null
              ? "Unknown"
              : tile.transparency!.toInt().toString(),
          'Location': tile.location,
          'Latitude': TextEditingController(
              text: decimalDegreesToDMS(tile.latitude!, 'lat')),
          'Longitude': TextEditingController(
              text: decimalDegreesToDMS(tile.longitude!, 'long')),
        };

  @override
  _ShowDetailsState createState() => _ShowDetailsState();
}

class _ShowDetailsState extends State<_ShowDetails> {
  Future<void> updateDateTime(BuildContext context, String key) async {
    await showDatePicker(
      context: context,
      initialDate: widget.tile.time!,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((newDate) async {
      if (newDate == null) return;
      await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(widget.tile.time!),
      ).then((newTime) async {
        if (newTime == null) return;
        newDate = newDate!
            .add(Duration(hours: newTime.hour, minutes: newTime.minute));

        await confirmDialog(context, 'New Time: $newDate').then((v) {
          if (v != ConfirmAction.accept) return;
          widget.tableItems[key].text =
              "${newDate!.yMMMd} ${newDate!.hourMinute} (${newDate!.timeZoneName})";
          widget.tile.reference!.update({'dateTime': newDate});
          setState(() {});
        });
      });
    });
  }

  Future<void> updateTextData(BuildContext context, String key) async {
    final newValue = TextEditingController(
        text: widget.tableItems[key].runtimeType == TextEditingController
            ? widget.tableItems[key].text
            : widget.tableItems[key]);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${S.of(context).editing} "$key"'),
        contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
        content: TextField(controller: newValue),
        actions: [
          TextButton(
            child: Text(S.of(context).cancel),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(S.of(context).save),
            onPressed: () {
              confirmDialog(
                      context, '${S.of(context).newValue}: ${newValue.text}')
                  .then((value) {
                if (value != ConfirmAction.accept) return;
                widget.tableItems[key].runtimeType == TextEditingController
                    ? widget.tableItems[key].text = newValue.text
                    : widget.tableItems[key] = newValue.text;
                setState(() {});
                widget.tile.reference!
                    .update({key.toLowerCase(): newValue.text});
                Navigator.pop(context, newValue.text);
              });
            },
          ),
        ],
      ),
    ).then((value) => null);
  }

  Future<void> updateNumericData(BuildContext context, String key,
      {required bool decimal, required bool signed}) async {
    final newValue = TextEditingController(
        text: (key == 'Latitude'
                ? widget.tile.latitude
                : key == 'Longitude'
                    ? widget.tile.longitude
                    : num.tryParse(widget.tableItems[key].text))
            .toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${S.of(context).editing} "$key"'),
        contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
        content: TextField(
          controller: newValue,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        ),
        actions: [
          TextButton(
            child: Text(S.of(context).cancel),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(S.of(context).save),
            onPressed: () {
              final v = key == 'Latitude' || key == 'Longitude'
                  ? num.tryParse(newValue.text)
                  : int.tryParse(newValue.text);
              if (v == null) return;
              confirmDialog(
                      context, '${S.of(context).newValue}: ${newValue.text}')
                  .then((value) {
                if (value != ConfirmAction.accept) return;
                if (key == 'Latitude') {
                  widget.tableItems[key].text = decimalDegreesToDMS(v, 'lat');
                } else if (key == 'Longitude') {
                  widget.tableItems[key].text = decimalDegreesToDMS(v, 'long');
                } else {
                  widget.tableItems[key].text = newValue.text;
                }
                setState(() {});
                widget.tile.reference!.update({key.toLowerCase(): v});
                Navigator.pop(context, newValue.text);
              });
            },
          ),
        ],
      ),
    ).then((value) => null);
  }

  void _updateField(BuildContext context, String key) {
    switch (key) {
      case 'Date & Time':
        updateDateTime(context, key);
        break;
      case 'Messier':
      case 'NGC':
        updateNumericData(context, key, decimal: false, signed: false);
        break;
      case 'Latitude':
      case 'Longitude':
        updateNumericData(context, key, decimal: true, signed: true);
        break;
      case 'Location':
        updateTextData(context, key);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tile.title!),
        centerTitle: true,
      ),
      body: Column(children: [
        Expanded(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(120),
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(.1)
                },
                children: widget.tableItems.entries
                    .map(
                      (e) => TableRow(
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            (e.value.runtimeType == TextEditingController)
                                ? e.value.text
                                : e.value,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const [
                            'Date & Time',
                            'Location',
                            'NGC',
                            'Messier',
                            'Latitude',
                            'Longitude'
                          ].contains(e.key)
                              ? IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _updateField(context, e.key),
                                )
                              : const SizedBox(),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              child: widget.tile.equipment ?? const SizedBox(),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  const Text("Notes:", style: TextStyle(fontSize: 20)),
                  IconButton(
                      icon: const Icon(Icons.add_box_rounded),
                      onPressed: _addNote)
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.tile.notes!.length,
                itemBuilder: (context, index) => Dismissible(
                  key: Key(widget.tile.notes![index]),
                  background: Container(color: Colors.red.shade700),
                  child: ListTile(
                    leading: Text("${index + 1}"),
                    title: Text(widget.tile.notes![index]),
                    onTap: () => _editNote(context, index),
                  ),
                  confirmDismiss: (dir) => confirmDeleteTile(context),
                  onDismissed: (dir) => widget.tile.notes!.removeAt(index),
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ButtonBar(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.close_rounded),
                label: Text(S.of(context).closeDetails),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text(S.of(context).deleteObservation),
                onPressed: () async =>
                    confirmDeleteTile(context).then((e) => e == null
                        ? null
                        : e
                            ? _deleteObservation(context)
                            : null),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void _addNote() async {
    final textController = TextEditingController();
    final response = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).addNote),
        content: TextField(
          controller: textController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 5,
          minLines: 2,
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.done),
            label: const Text("Ok"),
            onPressed: () => Navigator.pop(context, true),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );

    if (response ?? false) {
      setState(() => widget.tile.notes!.add(textController.text));
    }
  }

  void _editNote(BuildContext context, int index) async {
    final textController =
        TextEditingController(text: widget.tile.notes![index]);
    final response = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).editNote),
        content: TextField(
          controller: textController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 5,
          minLines: 2,
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.done),
            label: const Text("Ok"),
            onPressed: () => Navigator.pop(context, true),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );

    if (response ?? false) {
      setState(() => widget.tile.notes![index] = textController.text);
    }
  }

  void _deleteObservation(BuildContext context) async {
    final store = FirebaseFirestore.instance;
    final collectionPath =
        'users/${FirebaseAuth.instance.currentUser!.uid}/observations/';
    await store
        .collection(collectionPath)
        .where('title', isEqualTo: widget.tile.title)
        .where('dateTime', isEqualTo: widget.tile.time)
        .get()
        .then((result) async {
      if (result.size != 1) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Column(children: [
              Text(S.of(context).unableToDeleteTheObject),
              Text(result.toString()),
            ]),
          ),
        );
        return await Future.delayed(
            const Duration(seconds: 1), () => Navigator.pop(context));
      }
      // else clause
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      selectedTiles.remove(result.docs[0].reference);
      await store
          .doc(collectionPath + result.docs[0].id)
          .delete()
          .then((value) {
        Navigator.pop(context);
        Navigator.pop(context);
      });
      return;
    });
  }
}
