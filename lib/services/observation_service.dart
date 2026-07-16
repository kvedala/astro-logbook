import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/observation_data.dart';

class ObservationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get _userPath => 'users/${_auth.currentUser?.uid ?? ''}';

  static Future<List<ObservationData>> getObservations({
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore
        .collection('$_userPath/observations')
        .orderBy('dateTime', descending: true);

    if (limit != null) query = query.limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => ObservationData.fromJson(
            doc.data() as Map<String, dynamic>,
            reference: doc.reference,
          ),
        )
        .toList();
  }

  static Future<void> saveObservation(ObservationData observation) async {
    await _firestore
        .collection('$_userPath/observations')
        .add(observation.toJson());
  }

  static Future<void> updateObservation(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) async {
    await reference.update(data);
  }

  static Future<void> deleteObservation(DocumentReference reference) async {
    await reference.delete();
  }
}
