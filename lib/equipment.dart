import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Get and display equipment details.
class Equipment extends StatelessWidget {
  /// DB reference to the equipment document
  final DocumentReference reference;

  final void Function() onTap;

  /// Generate equipment from a DB query snapshot
  ///
  /// Helful to get equipment directly from dB query result
  /// ```
  /// final docs = await firestore
  ///     .collection('users/' + auth.currentUser.uid + "/equipment")
  ///     .get();
  /// docs.docs.forEach((query) => _equipments.add(Equipment.fromQuery(query)));
  /// ````
  Equipment.fromQuery(QueryDocumentSnapshot snap, {this.onTap})
      : reference = snap.reference {
    reference.get()..then((value) => _data.add(value));
  }

  /// Build equipment from a DB reference
  Equipment.fromReference(DocumentReference ref, {this.onTap})
      : reference = ref {
    reference.get()..then((value) => _data.add(value));
  }

  /// Procedure to add a new equipment in the user DB
  ///
  /// Returns [true] if new equipment was added else, [false].
  static Future<bool> addEquipment(BuildContext context,
      {Map<String, dynamic> inData, DocumentReference reference}) async {
    Map<String, dynamic> data = {
      'telescope': inData == null ? "" : inData['telescope'],
      'aperture': inData == null ? null : inData['aperture'],
      'focalLength': inData == null ? null : inData['focalLength'],
      'mount': inData == null ? "" : inData['mount'],
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
            label: Text(reference == null ? "Add" : "Update"),
            onPressed: () async {
              if (!_equipmentKey.currentState.validate()) return;
              _equipmentKey.currentState.save();
              reference == null
                  ? await FirebaseFirestore.instance
                      .collection('users/' +
                          FirebaseAuth.instance.currentUser.uid +
                          '/equipments')
                      .add(data)
                      .whenComplete(() {
                      Navigator.pop(context);
                      _returnVal = true;
                    })
                  : await FirebaseFirestore.instance
                      .doc(reference.path)
                      .update(data)
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

  final List<DocumentSnapshot> _data = [];

  @override
  Widget build(BuildContext context) {
    // if (_data['telescope'] == null) print("got here");
    return _data.isEmpty
        ? FutureBuilder<DocumentSnapshot>(
            future: reference.get()..then((value) => _data.add(value)),
            builder: (context, snap) =>
                snap.connectionState != ConnectionState.done
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : _buildTile(snap.data),
          )
        : _buildTile(_data[0]);
  }

  Widget _buildTile(DocumentSnapshot data) {
    final Map<String, dynamic> _data = data.data();

    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(_data['telescope'] +
          " (${_data['aperture']}mm, f/" +
          (_data['focalLength'] / _data['aperture']).toStringAsFixed(1) +
          ")"),
      subtitle: Text(_data['mount']),
      onTap: onTap,
    );
  }
}
