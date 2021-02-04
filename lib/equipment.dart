import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Get and display equipment details.
class Equipment extends StatelessWidget {
  /// DB reference to the equipment document
  DocumentReference reference;

  /// DB equipment document details
  Map<String, dynamic> _details;

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
        _details = snap.data();

  /// Build equipment from a DB reference
  Equipment.fromReference(DocumentReference ref) {
    if (ref != null) {
      reference = ref;
      _buildDetailsFromRef(ref);
    }
  }

  void _buildDetailsFromRef(DocumentReference ref) async {
    final doc = await FirebaseFirestore.instance.doc(ref.path).get();
    _details = doc.data();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
