import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

class AddObservationPage extends StatefulWidget {
  _AddObservationPageState createState() => _AddObservationPageState();
}

class _AddObservationPageState extends State<AddObservationPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _responses = {
    'title': "",
    'ngc': null,
    'messier': null,
    'fileName': "",
    'latitude': null,
    'longitude': null,
    'dateTime': null,
    'notes': <String>[],
  };
  final _filenameTextController = TextEditingController();
  List<String> _possibleLocations = [""];
  String _isFileValid;
  String _formattedLatitude = "";
  String _formattedLongitude = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Record observation"),
      ),
      body: FutureBuilder<Position>(
        future: _getCurrentPosition(),
        builder: (context, snapshot) => Container(
          padding: EdgeInsets.all(10),
          child: snapshot.connectionState != ConnectionState.done
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
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
                                      initialValue: _responses['messier'],
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              signed: false, decimal: false),
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
                                        return t == null
                                            ? null
                                            : t <= 0
                                                ? "Cannot be negative"
                                                : t > 110
                                                    ? "Messier catalog numbers are "
                                                        "only upto 110"
                                                    : null;
                                      },
                                      autovalidateMode: AutovalidateMode.always,
                                      onSaved: (value) =>
                                          _responses['messier'] = value,
                                      onChanged: (value) =>
                                          _responses['messier'] = value,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: "NGC #",
                                      ),
                                      initialValue: _responses['ngc'],
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
                                      onSaved: (value) =>
                                          _responses['ngc'] = value,
                                      onChanged: (value) =>
                                          _responses['ngc'] = value,
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
                        TextFormField(
                          decoration: InputDecoration(
                            icon: Icon(Icons.image_rounded),
                            labelText: "Image file to upload (if any)",
                          ),
                          controller: _filenameTextController,
                          onTap: _pickFile,
                          readOnly: true,
                          validator: (value) => _isFileValid,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
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
                          padding: EdgeInsets.symmetric(vertical: 5),
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
                          padding: EdgeInsets.symmetric(vertical: 5),
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
                          padding: EdgeInsets.symmetric(vertical: 5),
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
                          padding: EdgeInsets.symmetric(vertical: 5),
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
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
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
          .collection('users/' +
              auth.currentUser.uid +
              "/" +
              DateFormat.yMMMd().format(_responses['dateTime']))
          .doc(DateFormat.Hm().format(_responses['dateTime']))
          .set(_responses);
    } catch (e) {
      print(e);
      return false;
    }
    print("Success");
    return false;
  }

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
