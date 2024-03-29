import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as gps;

import 'equipment.dart';
import 'slider_widget.dart';
import 'utils.dart';

/// Convenient class for observational data
///
/// TODO: Optimize JSON serialization using automatic code generation: https://pub.dev/packages/json_serializable
class ObservationData {
  /// Title of observation
  final String? title;

  /// NGC catalog number
  final int? ngc;

  /// Messier catalog number
  final int? messier;

  /// Path of any image file to add
  final String? fileName;

  /// latitude of location of observation
  final num? latitude;

  /// longitude of location of observation
  final num? longitude;

  /// Address of location of observation
  final String? location;

  /// [Equipment] details for observation
  final Equipment equipment;

  /// Date and time of observation
  final DateTime? dateTime;

  /// Sky seeing at the time of observation
  final num? seeing;

  /// Sky visibility at the time of observation
  final num? visibility;

  /// Sky transparency at the time of observation
  final num? transparency;

  /// list of notes and observations
  final List<String> notes;

  /// dB document reference
  final DocumentReference? reference;

  static dynamic _valueFromJSON(Map<String, dynamic> json, String key) =>
      json.containsKey(key) ? json[key] : null;

  // ObservationData(this.title,
  //     {this.dateTime,
  //     this.equipment,
  //     this.fileName,
  //     this.latitude,
  //     this.location,
  //     this.longitude,
  //     this.messier,
  //     this.ngc,
  //     this.notes,
  //     this.seeing,
  //     this.transparency,
  //     this.visibility});

  ObservationData.fromJSON(Map<String, dynamic> json, {this.reference})
      : title = _valueFromJSON(json, 'title'),
        ngc = _valueFromJSON(json, 'ngc'),
        visibility = (_valueFromJSON(json, 'visibility')),
        seeing = (_valueFromJSON(json, 'seeing')),
        transparency = (_valueFromJSON(json, 'transparency')),
        messier = _valueFromJSON(json, 'messier'),
        fileName = _valueFromJSON(json, 'fileName'),
        latitude = _valueFromJSON(json, 'latitude'),
        longitude = _valueFromJSON(json, 'longitude'),
        location = _valueFromJSON(json, 'location'),
        equipment = Equipment.fromReference(_valueFromJSON(json, 'equipment')),
        dateTime = _valueFromJSON(json, 'dateTime').toDate(),
        notes = List<String>.from(_valueFromJSON(json, 'notes'));

  Map<String, dynamic> toJSON() => {
        'title': title,
        'ngc': ngc,
        'seeing': seeing,
        'visibility': visibility,
        'transparency': transparency,
        'messier': messier,
        'fileName': fileName,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'dateTime': dateTime,
        'notes': notes,
        'equipment': equipment.reference,
        'reference': reference,
      };
}

/// Widget to add observation data to DB
class AddObservationPage extends StatefulWidget {
  const AddObservationPage({super.key});

  @override
  State<AddObservationPage> createState() => _AddObservationPageState();
}

class _AddObservationPageState extends State<AddObservationPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _responses = {
    'title': "",
    'ngc': null,
    'visibility': null,
    'seeing': null,
    'transparency': null,
    'messier': null,
    // 'fileName': "",
    'latitude': null,
    'longitude': null,
    'location': null,
    'dateTime': null,
    'notes': <String>[],
    'equipment': null
  };

  // final _filenameTextController = TextEditingController();
  List<String> _possibleLocations = [""];
  List<Equipment> _equipments = [];
  // String _isFileValid;
  final TextEditingController _dateTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.setCurrentScreen(screenName: "Add observation");
    _loadData(context);
    _dateTimeController.text = _responses['longitude'] == null
        ? ""
        : _responses['longitude'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return
        //  FutureBuilder(
        //   future: _responses['longitude'] == null
        //       ? _loadData(context)
        //       : Future.value(true),
        //   builder: (context, snap) =>
        Scaffold(
      appBar: AppBar(
        title: const Text("Record observation"),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
        child: _responses['longitude'] == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: "Title",
                                ),
                                initialValue: _responses['title'],
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                readOnly: false,
                                validator: (value) => value == null
                                    ? "Cannot be NULL"
                                    : value.isEmpty
                                        ? "Cannot be empty"
                                        : null,
                                onSaved: (value) => _responses['title'] = value,
                                onChanged: (value) =>
                                    _responses['title'] = value,
                              ),
                            ),
                            Expanded(
                              child: Row(children: [
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: "Messier #",
                                    ),
                                    initialValue: _responses['messier'] == null
                                        ? ""
                                        : _responses['messier'].toString(),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      signed: false,
                                      decimal: false,
                                    ),
                                    readOnly: false,
                                    inputFormatters: [
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) => newValue.text
                                                  .contains(RegExp(r'[^0-9]'))
                                              ? oldValue
                                              : newValue)
                                    ],
                                    validator: (value) {
                                      if (value!.isEmpty) return null;
                                      final t = int.tryParse(value);
                                      if (t == null) return null;
                                      if (t <= 0) return "Cannot be negative";
                                      if (t > 110) {
                                        return "Messier catalog numbers are "
                                            "only upto 110";
                                      }
                                      return null;
                                    },
                                    autovalidateMode: AutovalidateMode.always,
                                    onSaved: (value) => _responses['messier'] =
                                        int.tryParse(value!),
                                    onChanged: (value) =>
                                        _responses['messier'] =
                                            int.tryParse(value),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: "NGC #",
                                    ),
                                    initialValue: _responses['ngc'] == null
                                        ? ""
                                        : _responses['ngc'].toString(),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(),
                                    readOnly: false,
                                    validator: (value) {
                                      if (value!.isEmpty) return null;
                                      final t = int.tryParse(value);
                                      return t == null
                                          ? "Not a valid number"
                                          : t <= 0
                                              ? "Cannot be negative"
                                              : null;
                                    },
                                    autovalidateMode: AutovalidateMode.always,
                                    onSaved: (value) => _responses['ngc'] =
                                        int.tryParse(value!),
                                    onChanged: (value) =>
                                        _responses['ngc'] = int.tryParse(value),
                                    inputFormatters: [
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) => newValue.text
                                                  .contains(RegExp(r'[^0-9]'))
                                              ? oldValue
                                              : newValue)
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      // TextFormField(
                      //   decoration: InputDecoration(
                      //     icon: Icon(Icons.image_rounded),
                      //     labelText: "Image file to upload (if any)",
                      //   ),
                      //   controller: _filenameTextController,
                      //   onTap: _pickFile,
                      //   readOnly: true,
                      //   validator: (value) => _isFileValid,
                      // ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Latitude",
                              ),
                              initialValue: _responses['latitude'] == null
                                  ? ""
                                  : _responses['latitude'].toString(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      signed: true, decimal: true),
                              // readOnly: true,
                              validator: (value) {
                                final number = num.tryParse(value!);
                                if (number == null) return "Not a number";
                                if (number < -90 || number > 90) {
                                  return "Invalid range";
                                }
                                return null;
                              },
                              onSaved: (value) =>
                                  _responses['latitude'] = num.parse(value!),
                              onChanged: (value) {
                                final numeric = num.tryParse(value);
                                if (numeric == null) return;
                                setState(
                                    () => _responses['latitude'] = numeric);
                                _updateAddresses();
                              },
                            ),
                          ),
                          Text(
                            _responses['latitude'] == null
                                ? ""
                                : decimalDegreesToDMS(
                                    _responses['latitude'], 'lat'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Longitude",
                              ),
                              initialValue: _responses['longitude'] == null
                                  ? ""
                                  : _responses['longitude'].toString(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      signed: true, decimal: true),
                              // readOnly: true,
                              validator: (value) {
                                final number = num.tryParse(value!);
                                if (number == null) return "Not a number";
                                if (number < -180 || number > 180) {
                                  return "Invalid range";
                                }
                                return null;
                              },
                              onSaved: (value) =>
                                  _responses['longitude'] = num.parse(value!),
                              onChanged: (value) {
                                final numeric = num.tryParse(value);
                                if (numeric == null) return;
                                setState(
                                    () => _responses['longitude'] = numeric);
                                _updateAddresses();
                                // longitudeWidget.build(context);
                              },
                            ),
                          ),
                          Text(
                            _responses['longitude'] == null
                                ? ""
                                : decimalDegreesToDMS(
                                    _responses['longitude'], 'long'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _possibleLocations.isEmpty
                            ? TextFormField(
                                decoration: const InputDecoration(
                                  labelText: "Location - Enter Address",
                                ),
                                initialValue: _responses['location'],
                                keyboardType: TextInputType.streetAddress,
                                // readOnly: false,
                                validator: (value) =>
                                    value!.isEmpty ? "Cannot be empty" : null,
                                onSaved: (value) =>
                                    _responses['location'] = value,
                              )
                            : DropdownButtonFormField(
                                isExpanded: true,
                                isDense: false,
                                decoration: const InputDecoration(
                                  labelText: "Location",
                                ),
                                value: _responses['location'],
                                items: List.generate(
                                  _possibleLocations.length,
                                  (index) => DropdownMenuItem(
                                    value: _possibleLocations[index],
                                    child: Text(
                                      _possibleLocations[index],
                                      softWrap: true,
                                    ),
                                  ),
                                ),
                                onChanged: (dynamic newItem) => setState(
                                    () => _responses['location'] = newItem),
                                validator: (dynamic value) => value == null
                                    ? "Value cannot be null"
                                    : (value.isEmpty
                                        ? "Value cannot be empty"
                                        : null),
                                onSaved: (dynamic value) =>
                                    _responses['location'] = value,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Expanded(
                            child: DropdownButtonFormField<DocumentReference>(
                              isExpanded: true,
                              isDense: false,
                              decoration: const InputDecoration(
                                labelText: "Equipment used",
                              ),
                              value: _responses['equipment'],
                              items: _equipments.isEmpty
                                  ? []
                                  : List.generate(
                                      _equipments.length,
                                      (index) => DropdownMenuItem(
                                        value: _equipments[index].reference,
                                        child: _equipments[index],
                                      ),
                                    ),
                              onChanged: (newItem) => setState(
                                  () => _responses['equipment'] = newItem),
                              validator: (value) =>
                                  value == null ? "Value cannot be null" : null,
                              onSaved: (value) =>
                                  _responses['equipment'] = value,
                            ),
                          ),
                          IconButton(
                              icon: const Icon(Icons.add_link),
                              onPressed: () =>
                                  Equipment.addEquipment(context).then(
                                    (v) => _loadEquipment(context, force: true)
                                        .then((v) => setState(() {})),
                                  )),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: "Date & Time of observation",
                          ),
                          controller: _dateTimeController,
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                                context: context,
                                initialDate: _responses['dateTime'],
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now());
                            if (date == null) return;
                            final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                    _responses['dateTime']));
                            if (time == null) return;

                            _responses['dateTime'] = DateTime(date.year,
                                date.month, date.day, time.hour, time.minute);
                            setState(() => _dateTimeController.text =
                                DateFormat('dd MMM, yyyy HH:mm')
                                    .format(_responses['dateTime']));
                          },
                          validator: (value) =>
                              value!.isEmpty ? "Cannot be empty" : null,
                        ),
                      ),
                      Row(children: [
                        Expanded(
                          child: SliderOption(
                            "Seeing",
                            (value) => _responses['seeing'] = value,
                            initialValue: _responses['seeing'] ?? 0,
                            minValue: 1.0,
                            maxValue: 5.0,
                            divisions: 4,
                            prefixIcon: Icons.remove_red_eye,
                          ),
                        ),
                        // Expanded(
                        //   child: SliderOption(
                        //     "Visibility",
                        //     (value) => _responses['visibility'] = value,
                        //     initialValue: _responses['visibility'] ?? 0,
                        //     minValue: 1.0,
                        //     maxValue: 5.0,
                        //     divisions: 4,
                        //     prefixIcon: Icons.visibility,
                        //   ),
                        // ),
                        Expanded(
                          child: SliderOption(
                            "Transparency",
                            (value) => _responses['transparency'] = value,
                            initialValue: _responses['transparency'] ?? 0,
                            minValue: 1.0,
                            maxValue: 5.0,
                            divisions: 4,
                            prefixIcon: Icons.cloud_circle,
                          ),
                        ),
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Notes:",
                              style: TextStyle(fontSize: 18),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded),
                              // color: Colors.white,
                              onPressed: () => _addNote(context),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _responses['notes'].length == 0
                            ? const SizedBox()
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _responses['notes'].length,
                                itemBuilder: (context, index) => Dismissible(
                                  key: Key(_responses['notes'][index]),
                                  background: Container(
                                    color: Colors.red,
                                  ),
                                  child: ListTile(
                                    leading: Text("${index + 1}"),
                                    title: Text(_responses['notes'][index]),
                                    onTap: () => _addNote(context, index),
                                  ),
                                  onDismissed: (event) => setState(() =>
                                      _responses['notes'].removeAt(index)),
                                ),
                              ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton.icon(
                              label: const Text("Submit"),
                              icon: const Icon(Icons.send_rounded),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  await saveToDB().then(
                                      (v) => v ? Navigator.pop(context) : null);
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              label: const Text("Cancel"),
                              icon: const Icon(Icons.cancel_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ]),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _addNote(BuildContext context, [int index = -1]) async {
    final noteController = TextEditingController(
        text: index == -1 ? null : _responses['notes'][index]);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == -1 ? "Add Note:" : "Edit Note:"),
        content: Container(
          constraints: BoxConstraints.loose(const Size(200, 200)),
          child: TextField(
            textCapitalization: TextCapitalization.sentences,
            controller: noteController,
            maxLines: 5,
            minLines: 3,
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.done),
            label: const Text("Accept"),
            onPressed: () {
              if (noteController.text.isNotEmpty) {
                setState(() {
                  if (index == -1) {
                    _responses['notes'].add(noteController.text);
                  } else {
                    _responses['notes'][index] = noteController.text;
                  }
                });
              }
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel_rounded),
            label: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Function to save data to DB
  ///
  /// Returns [true] if data was saved, else [false].
  Future<bool> saveToDB() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    try {
      await firestore
          .collection('users/${auth.currentUser!.uid}/observations')
          .add(_responses)
          .then((ref) async => await FirebaseAnalytics.instance.logEvent(
                name: "New Observation",
                parameters: {"path": ref.path},
              ));
    } catch (e) {
      // debugPrint(e);
      return false;
    }
    // debugPrint("Success");
    return true;
  }

  /// Get current address from GPS coordinates
  Future<void> _getCurrentPosition() async {
    if (_responses['latitude'] != null && _responses['longitude'] != null) {
      return;
    }
    final location = gps.Location();
    if (!await location.requestService()) return;

    final permission = await location.requestPermission();
    if (permission == gps.PermissionStatus.granted ||
        permission == gps.PermissionStatus.grantedLimited) {
      final value = await location.getLocation().timeout(
          const Duration(seconds: 5),
          onTimeout: () =>
              gps.LocationData.fromMap({'latitude': 0, 'longitude': 0}));
      final temp = DateTime.fromMillisecondsSinceEpoch(value.time!.toInt());
      if (mounted) {
        setState(() {
          _responses['latitude'] = value.latitude;
          _responses['longitude'] = value.longitude;
          _responses['dateTime'] =
              DateTime(temp.year, temp.month, temp.day, temp.hour, temp.minute);
        });
      }

      if (kIsWeb) {
        _possibleLocations.clear();
        return;
      }

      await _updateAddresses();
    }
    return;
  }

  Future<void> _updateAddresses() async {
    try {
      final places = await placemarkFromCoordinates(
          _responses['latitude'], _responses['longitude']);
      if (mounted) {
        setState(() {
          _possibleLocations = List.generate(
              places.length,
              (index) =>
                  "${places[index].name!}, ${places[index].subLocality!}, ${places[index].locality!}, ${places[index].country!} ${places[index].postalCode!}",
              growable: false);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      _possibleLocations.clear();
      // final responses = await http.get(Uri.https(
      //     'maps.googleapis.com',
      //     '/maps/api/'
      //         "geocode/json",
      //     {
      //       "latlng": "${_responses['latitude']},"
      //           "${_responses['longitude']}",
      //       'key': "AIzaSyDCPJfmW4Nn0U3qVgT_KatItS0I9nIJZIs"
      //     }));
      // if (responses.statusCode != 200) {
      //   _possibleLocations = [];
      //   return;
      // }
      // inspect(responses);
    }
  }

  /// Get the list of user's equipment from DB
  Future<void> _loadEquipment(BuildContext context,
      {bool force = false}) async {
    if (_equipments.isNotEmpty && !force) return;

    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    try {
      final docs = await firestore
          .collection('users/${auth.currentUser!.uid}/equipments')
          .get();
      _equipments =
          docs.docs.map((query) => Equipment.fromQuery(query)).toList();
      return;
    } catch (e) {
      // debugPrint(e);
      return;
    }
  }

  /// Perform initial data load operations
  Future<void> _loadData(BuildContext context) async {
    await Future.wait([_getCurrentPosition(), _loadEquipment(context)]);
  }

  // void _pickFile() async {
  //   final result = await FilePicker.platform.pickFiles(
  //     type: FileType.image,
  //   );
  //   if (result == null) return;

  //   final path = result.paths[0];
  //   _responses['fileName'] = path;
  // _isFileValid = (await File(path).exists()) ? null : "File does not exist";
  // final fileStats = await File(path).stat();
  // await showDialog(
  //   context: context,
  //   builder: (context) => AlertDialog(
  //     content: Container(
  //       child: Column(
  //         children: [
  //           Text("File size: " +
  //               (fileStats.size / (1024 * 1024)).toStringAsFixed(2) +
  //               "MB"),
  //           Text("File modified: ${fileStats.modified}"),
  //         ],
  //       ),
  //     ),
  //   ),
  // );
  //   setState(() => _filenameTextController.text = path);
  // }
}
