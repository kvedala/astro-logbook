import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Get and display equipment details.
///
/// TODO: Optimize JSON serialization using automatic code generation: https://pub.dev/packages/json_serializable
class Equipment extends StatelessWidget {
  /// DB reference to the equipment document
  final DocumentReference? reference;

  final void Function()? onTap;

  /// Generate equipment from a DB query snapshot
  ///
  /// Helful to get equipment directly from dB query result
  /// ```
  /// final docs = await firestore
  ///     .collection('users/' + auth.currentUser.uid + "/equipment")
  ///     .get();
  /// docs.docs.forEach((query) => _equipments.add(Equipment.fromQuery(query)));
  /// ````
  Equipment.fromQuery(QueryDocumentSnapshot snap, {this.onTap, super.key})
      : reference = snap.reference {
    reference!.get().then((value) => _data.add(value));
  }

  /// Build equipment from a DB reference
  Equipment.fromReference(DocumentReference? ref, {this.onTap, super.key})
      : reference = ref {
    reference!.get().then((value) => _data.add(value));
  }

  /// Procedure to add a new equipment in the user DB
  ///
  /// if available, load data from the given [inData] map
  /// Keep the DB [reference] of the equipment details object
  /// Returns [true] if new equipment was added else, [false].
  static Future<bool> addEquipment(BuildContext context,
      {
      /// if available, load data from the given map
      Map<String, dynamic>? inData,

      /// Keep the DB reference of the equipment details object
      DocumentReference? reference}) async {
    Map<String, dynamic> data = {
      'telescope': inData == null ? "" : inData['telescope'],
      'aperture': inData == null ? null : inData['aperture'],
      'focalLength': inData == null ? null : inData['focalLength'],
      'mount': inData == null ? "" : inData['mount'],
      // 'filters': <String>[],
      // 'camera': "",
    };

    final equipmentKey = GlobalKey<FormState>();
    bool returnVal = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add new equipment"),
        content: Form(
          key: equipmentKey,
          autovalidateMode: AutovalidateMode.always,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: TextFormField(
                    decoration: const InputDecoration(
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
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Telescope Aperture (mm)",
                    ),
                    initialValue: data['aperture'] == null
                        ? ""
                        : data['aperture'].toString(),
                    keyboardType: const TextInputType.numberWithOptions(),
                    readOnly: false,
                    validator: (value) {
                      num? number = num.tryParse(value!);
                      return number == null
                          ? "Not a valid number"
                          : number < 0
                              ? "Cannot be negative"
                              : null;
                    },
                    onSaved: (value) => data['aperture'] = num.parse(value!),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Focal Length (mm)",
                    ),
                    initialValue: data['focalLength'] == null
                        ? ""
                        : data['focalLength'].toString(),
                    keyboardType: const TextInputType.numberWithOptions(),
                    readOnly: false,
                    validator: (value) {
                      num? number = num.tryParse(value!);
                      return number == null
                          ? "Not a valid number"
                          : number < 0
                              ? "Cannot be negative"
                              : null;
                    },
                    onSaved: (value) => data['focalLength'] = num.parse(value!),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: TextFormField(
                    decoration: const InputDecoration(
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
            icon: const Icon(Icons.cancel_rounded),
            label: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.done_rounded),
            label: Text(reference == null ? "Add" : "Update"),
            onPressed: () async {
              if (!equipmentKey.currentState!.validate()) return;
              equipmentKey.currentState!.save();
              reference == null
                  ? await FirebaseFirestore.instance
                      .collection(
                          'users/${FirebaseAuth.instance.currentUser!.uid}/equipments')
                      .add(data)
                      .then((ref) async =>
                          await FirebaseAnalytics.instance.logEvent(
                            name: "New Equipment",
                            parameters: {"path": ref.path},
                          ))
                      .whenComplete(() {
                      Navigator.pop(context);
                      returnVal = true;
                    })
                  : await FirebaseFirestore.instance
                      .doc(reference.path)
                      .update(data)
                      .then((ref) async =>
                          await FirebaseAnalytics.instance.logEvent(
                            name: "Updated Equipment",
                            parameters: {"path": reference.path},
                          ))
                      .whenComplete(() {
                      Navigator.pop(context);
                      returnVal = true;
                    });
            },
          )
        ],
      ),
    );

    return returnVal;
  }

  final List<DocumentSnapshot> _data = [];

  @override
  Widget build(BuildContext context) {
    // if (_data['telescope'] == null) debugPrint("got here");
    return _data.isEmpty
        ? FutureBuilder<DocumentSnapshot>(
            future: reference!.get()..then((value) => _data.add(value)),
            builder: (context, snap) =>
                snap.connectionState != ConnectionState.done
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _buildTile(snap.data!),
          )
        : _buildTile(_data[0]);
  }

  Widget _buildTile(DocumentSnapshot data) {
    final Map<String, dynamic> dataMap = data.data() as Map<String, dynamic>;

    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(dataMap['telescope'] +
          " (${dataMap['aperture']}mm, f/" +
          (dataMap['focalLength'] / dataMap['aperture']).toStringAsFixed(1) +
          ")"),
      subtitle: Text(dataMap['mount']),
      onTap: onTap,
    );
  }
}
