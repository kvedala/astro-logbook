import 'dart:io';

import 'package:astro_log/equipment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

/// Convenient class for observational data
class ObservationData {
  /// Title of observation
  String title;

  /// NGC catalog number
  int ngc;

  /// Messier catalog number
  int messier;

  /// Path of any image file to add
  String fileName;

  /// latitude of location of observation
  num latitude;

  /// longitude of location of observation
  num longitude;

  /// Address of location of observation
  String location;

  /// [Equipment] details for observation
  Equipment equipment;

  /// Date and time of observation
  DateTime dateTime;

  /// list of notes and observations
  List<String> notes;

  static dynamic _valueFromJSON(Map<String, dynamic> json, String key) =>
      json.containsKey(key) ? json[key] : null;

  ObservationData(this.title);

  ObservationData.fromJSON(Map<String, dynamic> json)
      : title = _valueFromJSON(json, 'title'),
        ngc = _valueFromJSON(json, 'ngc'),
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
        'messier': messier,
        'fileName': fileName,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'dateTime': dateTime,
        'notes': notes,
        'equipment': equipment.reference,
      };
}

/// Widget to add observation data to DB
class AddObservationPage extends StatefulWidget {
  _AddObservationPageState createState() => _AddObservationPageState();
}

class _AddObservationPageState extends State<AddObservationPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _responses = {
    'title': "",
    'ngc': null,
    'messier': null,
    // 'fileName': "",
    'latitude': null,
    'longitude': null,
    'location': null,
    'dateTime': null,
    'notes': <String>[],
    'equipment': null,
  };
  final _filenameTextController = TextEditingController();
  List<String> _possibleLocations = [""];
  List<Equipment> _equipments = [];
  String _isFileValid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Record observation"),
      ),
      body: FutureBuilder(
        future: _loadData(context),
        builder: (context, snapshot) => Container(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
          child: snapshot.connectionState != ConnectionState.done
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
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
                                  onSaved: (value) =>
                                      _responses['title'] = value,
                                  onChanged: (value) =>
                                      _responses['title'] = value,
                                ),
                              ),
                              Expanded(
                                child: Row(children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: "Messier #",
                                      ),
                                      initialValue: _responses['messier'] ==
                                              null
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
                                            (oldValue, newValue) => newValue
                                                    .text
                                                    .contains(RegExp(r'[^0-9]'))
                                                ? oldValue
                                                : newValue)
                                      ],
                                      validator: (value) {
                                        if (value.isEmpty) return null;
                                        final t = int.tryParse(value);
                                        if (t == null) return null;
                                        if (t <= 0) return "Cannot be negative";
                                        if (t > 110)
                                          return "Messier catalog numbers are "
                                              "only upto 110";
                                        return null;
                                      },
                                      autovalidateMode: AutovalidateMode.always,
                                      onSaved: (value) =>
                                          _responses['messier'] =
                                              int.tryParse(value),
                                      onChanged: (value) =>
                                          _responses['messier'] =
                                              int.tryParse(value),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: "NGC #",
                                      ),
                                      initialValue: _responses['ngc'] == null
                                          ? ""
                                          : _responses['ngc'].toString(),
                                      keyboardType:
                                          TextInputType.numberWithOptions(),
                                      readOnly: false,
                                      validator: (value) {
                                        if (value.isEmpty) return null;
                                        final t = int.tryParse(value);
                                        return t == null
                                            ? "Not a valid number"
                                            : t <= 0
                                                ? "Cannot be negative"
                                                : null;
                                      },
                                      autovalidateMode: AutovalidateMode.always,
                                      onSaved: (value) => _responses['ngc'] =
                                          int.tryParse(value),
                                      onChanged: (value) => _responses['ngc'] =
                                          int.tryParse(value),
                                      inputFormatters: [
                                        TextInputFormatter.withFunction(
                                            (oldValue, newValue) => newValue
                                                    .text
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
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: "Latitude",
                                ),
                                initialValue: _responses['latitude'].toString(),
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                validator: (value) {
                                  final number = num.tryParse(value);
                                  if (number == null) return "Not a number";
                                  if (number < -90 || number > 90)
                                    return "Invalid range";
                                  return null;
                                },
                                onSaved: (value) =>
                                    _responses['latitude'] = num.parse(value),
                                onChanged: (value) {
                                  final numeric = num.tryParse(value);
                                  if (numeric == null) return;
                                  setState(
                                      () => _responses['latitude'] = numeric);
                                },
                              ),
                            ),
                            Text(
                              _decimalDegreesToDMS(
                                  _responses['latitude'], 'lat'),
                              style: TextStyle(fontSize: 14),
                            ),
                          ]),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: "Longitude",
                                ),
                                initialValue:
                                    _responses['longitude'].toString(),
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                validator: (value) {
                                  final number = num.tryParse(value);
                                  if (number == null) return "Not a number";
                                  if (number < -180 || number > 180)
                                    return "Invalid range";
                                  return null;
                                },
                                onSaved: (value) =>
                                    _responses['longitude'] = num.parse(value),
                              ),
                            ),
                            Text(
                              _decimalDegreesToDMS(
                                  _responses['longitude'], 'long'),
                              style: TextStyle(fontSize: 14),
                            ),
                          ]),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: DropdownButtonFormField(
                            isExpanded: true,
                            isDense: false,
                            decoration: InputDecoration(
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
                            onChanged: (newItem) => setState(
                                () => _responses['location'] = newItem),
                            validator: (value) => value == null
                                ? "Value cannot be null"
                                : (value.isEmpty
                                    ? "Value cannot be empty"
                                    : null),
                            onSaved: (value) => _responses['location'] = value,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            Expanded(
                              child: DropdownButtonFormField<DocumentReference>(
                                isExpanded: true,
                                isDense: false,
                                decoration: InputDecoration(
                                  labelText: "Equipment used",
                                ),
                                value: _responses['equipment'],
                                items: _equipments.length == 0
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
                                validator: (value) => value == null
                                    ? "Value cannot be null"
                                    : null,
                                onSaved: (value) =>
                                    _responses['equipment'] = value,
                              ),
                            ),
                            IconButton(
                                icon: Icon(Icons.add_link),
                                onPressed: () async =>
                                    await Equipment.addEquipment(context)
                                        ? setState(() {})
                                        : null),
                          ]),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: "Date & Time of observation",
                            ),
                            initialValue: _responses['dateTime'] == null
                                ? ""
                                : DateFormat('dd MMM, yyyy HH:mm')
                                    .format(_responses['dateTime']),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2010),
                                  lastDate: DateTime.now());
                              if (date == null) return;
                              final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now());
                              if (time == null) return;
                              setState(() {
                                _responses['dateTime'] = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute);
                              });
                            },
                            validator: (value) =>
                                value.isEmpty ? "Cannot be empty" : null,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Notes:"),
                              Ink(
                                decoration: const ShapeDecoration(
                                  color: Colors.lightBlue,
                                  shape: CircleBorder(),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.add_rounded),
                                  color: Colors.white,
                                  onPressed: () => _addNote(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: _responses['notes'].length == 0
                              ? SizedBox()
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
                                label: Text("Submit"),
                                icon: Icon(Icons.send_rounded),
                                onPressed: () async {
                                  if (_formKey.currentState.validate()) {
                                    _formKey.currentState.save();
                                    if (await saveToDB())
                                      Navigator.pop(context);
                                  }
                                },
                              ),
                              ElevatedButton.icon(
                                label: Text("Cancel"),
                                icon: Icon(Icons.cancel_rounded),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ]),
                      ],
                    ),
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
          constraints: BoxConstraints.loose(Size(200, 200)),
          child: TextField(
            textCapitalization: TextCapitalization.sentences,
            controller: noteController,
            maxLines: 5,
            minLines: 3,
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: Icon(Icons.done),
            label: Text("Accept"),
            onPressed: () {
              if (noteController.text.isNotEmpty)
                setState(() {
                  if (index == -1)
                    _responses['notes'].add(noteController.text);
                  else
                    _responses['notes'][index] = noteController.text;
                });
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.cancel_rounded),
            label: Text("Cancel"),
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
      // final userDoc =
      //     await firestore.collection('user').doc(auth.currentUser.uid).get();
      // if (!userDoc.exists)
      //   await firestore
      //       .collection('user/' +
      //           auth.currentUser.uid +
      //           DateFormat.yMd().format(_responses['dateTime']))
      //       .doc(DateFormat.Hm().format(_responses['dateTime']))
      //       .set(_responses);
      // else
      await firestore
          .collection('users/' + auth.currentUser.uid + "/observations")
          .add(_responses);
    } catch (e) {
      // print(e);
      return false;
    }
    // print("Success");
    return true;
  }

  /// Get current address from GPS coordinates
  ///
  ///
  Future<Position> _getCurrentPosition() async {
    if (_responses['latitude'] != null && _responses['longitude'] != null)
      return null;
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse)
      return Geolocator.getCurrentPosition()
        ..then((value) async {
          _responses['latitude'] = value.latitude;
          _responses['longitude'] = value.longitude;
          final places =
              await placemarkFromCoordinates(value.latitude, value.longitude);
          setState(() {
            _possibleLocations = List.generate(
                places.length,
                (index) =>
                    places[index].name +
                    ", " +
                    places[index].subLocality +
                    ", " +
                    places[index].locality +
                    ", " +
                    places[index].country +
                    " " +
                    places[index].postalCode,
                growable: false);
          });
        });
    return null;
  }

  /// Get the list of user's equipment from DB
  Future<List<Equipment>> _loadEquipment(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    try {
      final docs = await firestore
          .collection('users/' + auth.currentUser.uid + "/equipments")
          .get();
      _equipments =
          docs.docs.map((query) => Equipment.fromQuery(query)).toList();
      return _equipments;
    } catch (e) {
      // print(e);
      return [];
    }
  }

  /// Perform initial data load operations
  Future<void> _loadData(BuildContext context) async {
    await Future.wait([_getCurrentPosition(), _loadEquipment(context)]);
  }

  /// Convert decimal degrees to string degree-minute-second format
  String _decimalDegreesToDMS(num numeric, String latOrLong) {
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

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null) return;

    final path = result.paths[0];
    _responses['fileName'] = path;
    _isFileValid = (await File(path).exists()) ? null : "File does not exist";
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
    setState(() => _filenameTextController.text = path);
  }
}
