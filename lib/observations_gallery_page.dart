import 'package:astro_log/add_observation.dart';
import 'package:astro_log/gallary_tile.dart';
import 'package:astro_log/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ObservationsGallary extends StatelessWidget {
  final User _user;

  ObservationsGallary() : _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Observations Gallary"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getObservations(),
        builder: (context, snap) => snap.connectionState ==
                ConnectionState.waiting
            ? Center(
                child: CircularProgressIndicator(),
              )
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                itemCount: snap.data.docs.length,
                itemBuilder: (context, index) => snap.data == null
                    ? SizedBox()
                    : GallaryTile.fromObservation(
                        ObservationData.fromJSON(snap.data.docs[index].data()),
                      ),
              ),
      ),
      // ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_observation",
        child: Icon(Icons.add_rounded),
        onPressed: () => Navigator.pushNamed(context, AddObservationPageRoute),
      ),
    );
  }

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

class PhotographyGallary extends StatelessWidget {
  final User _user;

  PhotographyGallary() : _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Photography Gallary"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_photo",
        child: Icon(Icons.add_rounded),
        onPressed: () {},
      ),
    );
  }
}
