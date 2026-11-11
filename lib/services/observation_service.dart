import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/observation_data.dart';

/// Firestore access for the signed-in user's observations.
class ObservationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get _userPath => 'users/${_auth.currentUser?.uid ?? ''}';

  /// Fetch observations newest first, optionally starting after a page cursor.
  static Future<List<ObservationData>> getObservations({
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    // Keep the cursor aligned with the same descending order used for paging.
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

  /// Create a new observation document for the signed-in user.
  static Future<void> saveObservation(ObservationData observation) async {
    await _firestore
        .collection('$_userPath/observations')
        .add(observation.toJson());
  }

  /// Update only the provided fields without replacing the document.
  static Future<void> updateObservation(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) async {
    await reference.update(data);
  }

  /// Delete the observation identified by [reference].
  static Future<void> deleteObservation(DocumentReference reference) async {
    await reference.delete();
  }
}
