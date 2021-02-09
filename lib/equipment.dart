import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Get and display equipment details.
class Equipment extends StatelessWidget {
  /// DB reference to the equipment document
  final DocumentReference reference;

  /// DB equipment document details
  final Map<String, dynamic> _data;

  /// Generate equipment from a DB query snapshot
  ///
  /// Helful to get equipment directly from dB query result
  /// ```
  /// final docs = await firestore
  ///     .collection('users/' + auth.currentUser.uid + "/equipment")
  ///     .get();
  /// docs.docs.forEach((query) => _equipments.add(Equipment.fromQuery(query)));
  /// ````
  Equipment.fromQuery(QueryDocumentSnapshot snap)
      : reference = snap.reference,
        _data = snap.data();

  /// Build equipment from a DB reference
  Equipment.fromReference(DocumentReference ref)
      : reference = ref,
        _data = {} {
    if (ref != null) {
      _buildDetailsFromRef(ref);
    }
  }

  void _buildDetailsFromRef(DocumentReference ref) async {
    final doc = await FirebaseFirestore.instance.doc(ref.path).get();
    doc.data().forEach((key, value) => _data[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return _data == null
        ? Text("Telescope data not found")
        : ListTile(
            visualDensity: VisualDensity.compact,
            title: Text(_data['telescope'] +
                " (${_data['aperture']}mm, f/" +
                (_data['focalLength'] / _data['aperture']).toStringAsFixed(1) +
                ")"),
            subtitle: Text(_data['mount']),
          );
  }

  /// Procedure to add a new equipment in the user DB
  ///
  /// Returns [true] if new equipment was added else, [false].
  static Future<bool> addEquipment(BuildContext context) async {
    Map<String, dynamic> data = {
      'telescope': "",
      'aperture': null,
      'focalLength': null,
      'mount': "",
      // 'filters': <String>[],
      // 'camera': "",
    };

    final _equipmentKey = GlobalKey<FormState>();
    bool _returnVal = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add new equipment"),
        content: Form(
          key: _equipmentKey,
          autovalidateMode: AutovalidateMode.always,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Telescope ",
                    ),
                    initialValue: data['telescope'],
                    keyboardType: TextInputType.name,
                    readOnly: false,
                    validator: (value) => value == null
                        ? "Canot be NULL"
                        : value.isEmpty
                            ? "Cannot be empty"
                            : null,
                    onSaved: (value) => data['telescope'] = value,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Telescope Aperture (mm)",
                    ),
                    initialValue: data['aperture'] == null
                        ? ""
                        : data['aperture'].toString(),
                    keyboardType: TextInputType.numberWithOptions(),
                    readOnly: false,
                    validator: (value) {
                      num number = num.tryParse(value);
                      return number == null
                          ? "Not a valid number"
                          : number < 0
                              ? "Cannot be negative"
                              : null;
                    },
                    onSaved: (value) => data['aperture'] = num.parse(value),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Focal Length (mm)",
                    ),
                    initialValue: data['focalLength'] == null
                        ? ""
                        : data['focalLength'].toString(),
                    keyboardType: TextInputType.numberWithOptions(),
                    readOnly: false,
                    validator: (value) {
                      num number = num.tryParse(value);
                      return number == null
                          ? "Not a valid number"
                          : number < 0
                              ? "Cannot be negative"
                              : null;
                    },
                    onSaved: (value) => data['focalLength'] = num.parse(value),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Mount",
                    ),
                    initialValue: data['mount'],
                    keyboardType: TextInputType.name,
                    readOnly: false,
                    validator: (value) => value == null
                        ? "Cannot be NULL"
                        : value.isEmpty
                            ? "Cannot be empty"
                            : null,
                    onSaved: (value) => data['mount'] = value,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: Icon(Icons.cancel_rounded),
            label: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.done_rounded),
            label: Text("Add"),
            onPressed: () async {
              if (!_equipmentKey.currentState.validate()) return;
              _equipmentKey.currentState.save();
              await FirebaseFirestore.instance
                  .collection('users/' +
                      FirebaseAuth.instance.currentUser.uid +
                      '/equipments')
                  .add(data)
                  .whenComplete(() {
                Navigator.pop(context);
                _returnVal = true;
              });
            },
          )
        ],
      ),
    );

    return _returnVal;
  }
}
