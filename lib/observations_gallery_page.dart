import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_observation.dart';
import 'filter_widget.dart';
import 'gallary_tile.dart';

/// Page to display the observations as a gallery
class ObservationsGallary extends StatefulWidget {
  const ObservationsGallary({Key? key}) : super(key: key);

  _ObservationsGallaryState createState() => _ObservationsGallaryState();
}

class _ObservationsGallaryState extends State<ObservationsGallary> {
  @override
  void initState() {
    super.initState();
    // FirebaseAnalytics.instance.
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: "Observations Gallery");
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(children: [
      ObservationTabBar(() => setState(() {})),
      searchState['onlySearch']
          ? FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              future: FirebaseFirestore.instance
                  .collection('users/' +
                      FirebaseAuth.instance.currentUser!.uid +
                      '/observations')
                  .get()
                  .then((snap) => snap.docs
                      .where((doc) => selectedTiles.contains(doc.reference))
                      .toList(growable: false)),
              builder: (context, snap) => snap.connectionState !=
                      ConnectionState.done
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : !snap.hasData
                      ? SizedBox()
                      : Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: size.width > 845
                                  ? 6
                                  : size.width >= 670
                                      ? 4
                                      : size.width >= 550
                                          ? 3
                                          : 2,
                            ),
                            shrinkWrap: true,
                            itemCount: snap.data!.length,
                            itemBuilder: (context, index) =>
                                index >= snap.data!.length
                                    ? SizedBox()
                                    : GallaryTile.fromObservation(
                                        ObservationData.fromJSON(
                                          snap.data![index].data(),
                                        ),
                                        reference: snap.data![index].reference,
                                      ),
                          ),
                        ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _getObservations(),
              builder: (context, snap) {
                switch (snap.connectionState) {
                  case ConnectionState.none:
                    // case ConnectionState.waiting:
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    return !snap.hasData
                        ? SizedBox()
                        : Expanded(
                            child: GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: size.width > 845
                                    ? 6
                                    : size.width >= 670
                                        ? 4
                                        : size.width >= 550
                                            ? 3
                                            : 2,
                              ),
                              shrinkWrap: true,
                              itemCount: snap.data!.docs.length,
                              itemBuilder: (context, index) =>
                                  index >= snap.data!.docs.length
                                      ? SizedBox()
                                      : GallaryTile.fromObservation(
                                          ObservationData.fromJSON(
                                            snap.data!.docs[index].data()
                                                as Map<String, dynamic>,
                                          ),
                                          reference:
                                              snap.data!.docs[index].reference,
                                        ),
                            ),
                          );
                }
              }),
    ]);
  }

  /// Get user observations as a stream instead of bulk load
  Stream<QuerySnapshot> _getObservations() {
    // Stream<List<ObservationData>> _getObservations() {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    if (searchState['date'] != null)
      return firestore
          .collection('users/' + auth.currentUser!.uid + '/observations')
          .where('dateTime', isGreaterThanOrEqualTo: searchState['date'].start)
          .where('dateTime', isLessThanOrEqualTo: searchState['date'].end)
          // .orderBy('dateTime', descending: true)
          .snapshots(includeMetadataChanges: true);
    // .get();
    else if (searchState['messier'].isNotEmpty || searchState['ngc'].isNotEmpty)
      return firestore
          .collection('users/' + auth.currentUser!.uid + '/observations')
          .where('messier', isEqualTo: int.tryParse(searchState['messier']))
          .where('ngc', isEqualTo: int.tryParse(searchState['ngc']))
          // .where('title', arrayContains: stringSearchController.text)
          // .where('notes', arrayContains: stringSearchController)
          // .orderBy('dateTime', descending: true)
          .snapshots();
    else
      return firestore
          .collection('users/' + auth.currentUser!.uid + '/observations')
          .orderBy('dateTime', descending: true)
          .snapshots();
    // .map<List<ObservationData>>(
    //     (snapshot) => snapshot.docs.map<ObservationData>((doc) {
    //           return ObservationData.fromJSON(doc.data());
    //         }).toList());
  }
}
