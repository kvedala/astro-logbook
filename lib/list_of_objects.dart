import 'package:astro_log/ra_dec.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as gps;

import 'objects.dart';

/// Page to display the observations as a gallery
class ListOfObjects extends StatelessWidget {
  const ListOfObjects({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: "List of Messier Objects");
    // print("Test: ${DateTime.utc(1994, 6, 16, 18).JulianDay}"); // must be -2024.75
    return FutureBuilder<gps.LocationData?>(
      future: _getLocation(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Column(children: [
            CircularProgressIndicator(),
            Text("Getting current GPS location...")
          ]);
        if (snap.data == null)
          return Center(
            child: Text("No GPS!\nCannot compute Rise and Set times."),
          );
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              // return _saveMessierObjects();
              FirebaseFirestore.instance
                  .collection("/messier")
                  .orderBy("number")
                  .snapshots(),
          builder: (ctx, snap2) {
            // if (snap2.connectionState != ConnectionState.done)
            //   return Center(child: CircularProgressIndicator());
            if (snap2.data == null)
              // return Center(child: Text("No Data!"));
              return Column(children: [
                CircularProgressIndicator(),
                Text("Loading Messier data...")
              ]);
            return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection("users/" +
                      FirebaseAuth.instance.currentUser!.uid +
                      "/observations")
                  // .where("messier", isGreaterThan: 0)
                  .get(GetOptions(source: Source.cache)),
              builder: (context, snap3) => snap3.connectionState !=
                      ConnectionState.done
                  ? Column(children: [
                      CircularProgressIndicator(),
                      Text("Loading viewed data...")
                    ])
                  : ListView.builder(
                      itemCount: snap2.data?.size,
                      itemBuilder: (context, index) => Messier.fromJSON(
                          snap2.data!.docs[index].data(),
                          snap3.data!.docs
                              .where((element) =>
                                  snap2.data!.docs[index].data()['number'] ==
                                  element.data()["messier"])
                              .isNotEmpty,
                          snap.data!),
                    ),
            );
          },
        );
      },
    );
  }

  Future<gps.LocationData?> _getLocation() async {
    gps.Location location = new gps.Location();

    bool _serviceEnabled;
    gps.PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == gps.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != gps.PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }
}
