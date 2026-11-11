import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:collection/collection.dart';

import 'confirm_dialog.dart';
import 'generated/l10n.dart';
import 'utils.dart';
import 'equipment.dart';
import 'models/observation_data.dart';

/// Tracks the gallery tiles that are currently selected
List<DocumentReference?> selectedTiles = [];

/// Widget to display tile in the gallery view
class GallaryTile extends StatefulWidget {
  /// Observation displayed by this tile.
  final ObservationData observation;

  /// Widget to display tile in the gallery view
  const GallaryTile({super.key, required this.observation});

  @override
  State<GallaryTile> createState() => _GallaryTileState();
}

class _GallaryTileState extends State<GallaryTile> {
  late List<String> _notes;
  Equipment? _equipment;

  @override
  void initState() {
    super.initState();
    _resetObservation();
  }

  @override
  void didUpdateWidget(GallaryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observation != widget.observation) _resetObservation();
  }

  /// Reset editable state when the observation changes.
  void _resetObservation() {
    _notes = List.of(widget.observation.notes);
    final reference = widget.observation.equipmentReference;
    _equipment = reference == null ? null : Equipment.fromReference(reference);
  }

  bool get isSelected =>
      selectedTiles.any((ref) => ref == widget.observation.reference);

  @override
  Widget build(BuildContext context) {
    final observation = widget.observation;
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
                Text(observation.title!, style: const TextStyle(fontSize: 20)),
                observation.messier == null
                    ? const SizedBox()
                    : Text(
                        "${S.current.messierNumber} ${observation.messier}",
                        style: const TextStyle(fontSize: 15),
                      ),
                observation.ngc == null
                    ? const SizedBox()
                    : Text(
                        "${S.current.ngcNumber} ${observation.ngc}",
                        style: const TextStyle(fontSize: 15),
                      ),
                Text(
                  "${S.current.observationDate} ${observation.dateTime!.yMMMd} ${observation.dateTime!.hourMinute} (${observation.dateTime!.timeZoneName})",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        onTap: () async {
          final notes = _notes;
          final originalNotes = List<String>.of(notes);
          final reference = observation.reference;
          final equipment = _equipment;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _ShowDetails(observation, notes, equipment),
            ),
          );
          if (!const UnorderedIterableEquality<String>().equals(
            originalNotes,
            notes,
          )) {
            reference!.update({'notes': notes});
            debugPrint("${reference.path}: Updating the DB notes.");
          } else {
            debugPrint("${reference!.path}: NOT Updating the DB notes.");
          }
        },
        onLongPress: () {
          setState(
            () => isSelected
                ? selectedTiles.remove(observation.reference)
                : selectedTiles.add(observation.reference),
          );
        },
      ),
    );
  }
}

/// Page to display the details of observation
class _ShowDetails extends StatefulWidget {
  final ObservationData observation;
  final List<String> notes;
  final Equipment? equipment;

  /// convenient lookup table to display as table rows
  final Map<String, dynamic> tableItems;

  _ShowDetails(this.observation, this.notes, this.equipment)
    : tableItems = {
        'Messier': TextEditingController(
          text: observation.messier == null
              ? "-"
              : observation.messier.toString(),
        ),
        'NGC': TextEditingController(
          text: observation.ngc == null ? "-" : observation.ngc.toString(),
        ),
        'Date & Time': TextEditingController(
          text:
              "${observation.dateTime!.yMMMd} ${observation.dateTime!.hourMinute} (${observation.dateTime!.timeZoneName})",
        ),
        'Seeing': observation.seeing == null
            ? "Unknown"
            : observation.seeing!.toInt().toString(),
        'Visibility': observation.visibility == null
            ? "Unknown"
            : observation.visibility!.toInt().toString(),
        'Transparency': observation.transparency == null
            ? "Unknown"
            : observation.transparency!.toInt().toString(),
        'Location': observation.location,
        'Latitude': TextEditingController(
          text: decimalDegreesToDMS(observation.latitude!, 'lat'),
        ),
        'Longitude': TextEditingController(
          text: decimalDegreesToDMS(observation.longitude!, 'long'),
        ),
      };

  @override
  _ShowDetailsState createState() => _ShowDetailsState();
}

class _ShowDetailsState extends State<_ShowDetails> {
  Future<void> updateDateTime(BuildContext context, String key) async {
    await showDatePicker(
      context: context,
      initialDate: widget.observation.dateTime!,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((newDate) async {
      if (newDate == null) return;
      while (!context.mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!context.mounted) {
        Exception("Context not mounted");
        return;
      }
      await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(widget.observation.dateTime!),
      ).then((newTime) async {
        if (newTime == null) return;
        newDate = newDate!.add(
          Duration(hours: newTime.hour, minutes: newTime.minute),
        );
        while (!context.mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        if (!context.mounted) {
          Exception("Context not mounted");
          return;
        }
        await confirmDialog(context, 'New Time: $newDate').then((v) {
          if (v != ConfirmAction.accept) return;
          widget.tableItems[key].text =
              "${newDate!.yMMMd} ${newDate!.hourMinute} (${newDate!.timeZoneName})";
          widget.observation.reference!.update({'dateTime': newDate});
          setState(() {});
        });
      });
    });
  }

  Future<void> updateTextData(BuildContext context, String key) async {
    final newValue = TextEditingController(
      text: widget.tableItems[key].runtimeType == TextEditingController
          ? widget.tableItems[key].text
          : widget.tableItems[key],
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${S.current.editing} "$key"'),
        contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
        content: TextField(controller: newValue),
        actions: [
          TextButton(
            child: Text(S.current.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(S.current.save),
            onPressed: () {
              confirmDialog(
                context,
                '${S.current.newValue}: ${newValue.text}',
              ).then((value) async {
                if (value != ConfirmAction.accept) return;
                widget.tableItems[key].runtimeType == TextEditingController
                    ? widget.tableItems[key].text = newValue.text
                    : widget.tableItems[key] = newValue.text;
                setState(() {});
                widget.observation.reference!.update({
                  key.toLowerCase(): newValue.text,
                });
                while (!context.mounted) {
                  await Future.delayed(const Duration(milliseconds: 100));
                }
                if (!context.mounted) {
                  Exception("Context not mounted");
                  return;
                }
                Navigator.pop(context, newValue.text);
              });
            },
          ),
        ],
      ),
    ).then((value) => null);
  }

  Future<void> updateNumericData(
    BuildContext context,
    String key, {
    required bool decimal,
    required bool signed,
  }) async {
    final newValue = TextEditingController(
      text:
          (key == 'Latitude'
                  ? widget.observation.latitude
                  : key == 'Longitude'
                  ? widget.observation.longitude
                  : num.tryParse(widget.tableItems[key].text))
              .toString(),
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${S.current.editing} "$key"'),
        contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
        content: TextField(
          controller: newValue,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        ),
        actions: [
          TextButton(
            child: Text(S.current.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(S.current.save),
            onPressed: () {
              final v = key == 'Latitude' || key == 'Longitude'
                  ? num.tryParse(newValue.text)
                  : int.tryParse(newValue.text);
              if (v == null) return;
              confirmDialog(
                context,
                '${S.current.newValue}: ${newValue.text}',
              ).then((value) async {
                if (value != ConfirmAction.accept) return;
                if (key == 'Latitude') {
                  widget.tableItems[key].text = decimalDegreesToDMS(v, 'lat');
                } else if (key == 'Longitude') {
                  widget.tableItems[key].text = decimalDegreesToDMS(v, 'long');
                } else {
                  widget.tableItems[key].text = newValue.text;
                }
                setState(() {});
                widget.observation.reference!.update({key.toLowerCase(): v});
                while (!context.mounted) {
                  await Future.delayed(const Duration(milliseconds: 100));
                }
                if (!context.mounted) {
                  Exception("Context not mounted");
                  return;
                }
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
      appBar: AppBar(title: Text(widget.observation.title!), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Table(
                          columnWidths: const {
                            0: FixedColumnWidth(120),
                            1: FlexColumnWidth(),
                            2: FixedColumnWidth(48),
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
                                      (e.value.runtimeType ==
                                              TextEditingController)
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
                                          'Longitude',
                                        ].contains(e.key)
                                        ? IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _updateField(context, e.key),
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
                        child: widget.equipment ?? const SizedBox(),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        child: Row(
                          children: [
                            const Text(
                              "Notes:",
                              style: TextStyle(fontSize: 20),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_box_rounded),
                              onPressed: _addNote,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverList.builder(
                  itemCount: widget.notes.length,
                  itemBuilder: (context, index) => Dismissible(
                    key: Key(widget.notes[index]),
                    background: Container(color: Colors.red.shade700),
                    child: ListTile(
                      leading: Text("${index + 1}"),
                      title: Text(widget.notes[index]),
                      onTap: () => _editNote(context, index),
                    ),
                    confirmDismiss: (dir) => confirmDeleteTile(context),
                    onDismissed: (dir) => widget.notes.removeAt(index),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: OverflowBar(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.close_rounded),
                  label: Text(S.current.closeDetails),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: Text(S.current.deleteObservation),
                  onPressed: () async => confirmDeleteTile(context).then((
                    e,
                  ) async {
                    while (!context.mounted) {
                      await Future.delayed(const Duration(milliseconds: 100));
                    }
                    if (!context.mounted) {
                      Exception("Context not mounted");
                      return;
                    }
                    return e == null
                        ? null
                        : e
                        ? _deleteObservation(context)
                        : null;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addNote() async {
    final textController = TextEditingController();
    final response = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.current.addNote),
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
      setState(() => widget.notes.add(textController.text));
    }
  }

  void _editNote(BuildContext context, int index) async {
    final textController = TextEditingController(text: widget.notes[index]);
    final response = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.current.editNote),
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
      setState(() => widget.notes[index] = textController.text);
    }
  }

  void _deleteObservation(BuildContext context) async {
    final store = FirebaseFirestore.instance;
    final collectionPath =
        'users/${FirebaseAuth.instance.currentUser?.uid ?? ''}/observations/';
    await store
        .collection(collectionPath)
        .where('title', isEqualTo: widget.observation.title)
        .where('dateTime', isEqualTo: widget.observation.dateTime)
        .get()
        .then((result) async {
          while (!context.mounted) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (!context.mounted) {
            Exception("Context not mounted");
            return;
          }
          // Only delete when the title/time pair identifies exactly one document.
          if (result.size != 1) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Column(
                  children: [
                    Text(S.current.unableToDeleteTheObject),
                    Text(result.toString()),
                  ],
                ),
              ),
            );
            return await Future.delayed(const Duration(seconds: 1), () async {
              while (!context.mounted) {
                await Future.delayed(const Duration(milliseconds: 100));
              }
              if (!context.mounted) {
                Exception("Context not mounted");
                return;
              }
              Navigator.pop(context);
            });
          }
          // else clause
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
          selectedTiles.remove(result.docs[0].reference);
          await store.doc(collectionPath + result.docs[0].id).delete().then((
            value,
          ) async {
            while (!context.mounted) {
              await Future.delayed(const Duration(milliseconds: 100));
            }
            if (!context.mounted) {
              Exception("Context not mounted");
              return;
            }
            Navigator.pop(context);
            Navigator.pop(context);
          });
          return;
        });
  }
}
