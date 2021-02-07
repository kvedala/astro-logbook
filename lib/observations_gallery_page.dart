import 'package:astro_log/add_observation.dart';
import 'package:astro_log/gallary_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Page to display the observations as a gallery
class ObservationsGallary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return StreamBuilder<QuerySnapshot>(
      stream: _getObservations(),
      builder: (context, snap) => snap.connectionState ==
              ConnectionState.waiting
          ? Center(
              child: CircularProgressIndicator(),
            )
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size.width > 845
                    ? 6
                    : size.width >= 670
                        ? 4
                        : size.width >= 550
                            ? 3
                            : 2,
              ),
              shrinkWrap: true,
              itemCount: snap.data.docs.length,
              itemBuilder: (context, index) => snap.data == null
                  ? SizedBox()
                  : GallaryTile.fromObservation(
                      ObservationData.fromJSON(snap.data.docs[index].data()),
                    ),
            ),
    );
  }

  /// Get user observations as a stream instead of bulk load
  Stream<QuerySnapshot> _getObservations() {
    // Stream<List<ObservationData>> _getObservations() {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    return firestore
        .collection('users/' + auth.currentUser.uid + '/observations')
        .orderBy('dateTime', descending: true)
        .snapshots();
    // .map<List<ObservationData>>(
    //     (snapshot) => snapshot.docs.map<ObservationData>((doc) {
    //           return ObservationData.fromJSON(doc.data());
    //         }).toList());
  }
}

/// Page to display the observations as a gallery
class PhotographyGallary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("To be implemented...."),
    );
  }
}
