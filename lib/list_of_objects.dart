import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:location/location.dart' as gps;

import 'objects.dart';

bool messierWasViewed(Map<String, dynamic> object,
    Iterable<Map<String, dynamic>> observations) {
  final related = (object['ngcNumbers'] as List<dynamic>? ?? []).whereType<int>().toSet();
  return observations.any((observation) =>
      observation['messier'] == object['number'] ||
      related.contains(observation['ngc']));
}

/// Page to display the observations as a gallery
class ListOfObjects extends StatelessWidget {
  const ListOfObjects({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance
        .logScreenView(screenName: "List of Messier Objects");
    // print("Test: ${DateTime.utc(1994, 6, 16, 18).JulianDay}"); // must be -2024.75
    return FutureBuilder<gps.LocationData?>(
      future: _getLocation(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(children: [
              CircularProgressIndicator(),
              Text("Getting current GPS location...")
            ]),
          );
        }
        if (snap.data == null) {
          return const Center(
            child: Text("No GPS!\nCannot compute Rise and Set times."),
          );
        }
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
            if (snap2.data == null) {
              return const Column(children: [
                CircularProgressIndicator(),
                Text("Loading Messier data...")
              ]);
            }
            return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // Mark catalog entries as viewed when this user has a matching log.
              future: FirebaseFirestore.instance
                  .collection(
                      "users/${FirebaseAuth.instance.currentUser?.uid ?? ''}/observations")
                  // .where("messier", isGreaterThan: 0)
                  .get(const GetOptions(source: Source.serverAndCache)),
              builder: (context, snap3) {
                if (snap3.connectionState != ConnectionState.done) {
                  return const Column(children: [
                    CircularProgressIndicator(),
                    Text("Loading viewed data...")
                  ]);
                }
                if (snap3.hasError || !snap3.hasData) {
                  return Center(child: Text("Could not load observations: ${snap3.error}"));
                }
                return ListView.builder(
                  itemCount: snap2.data!.size,
                  itemBuilder: (context, index) => Messier.fromJSON(
                      snap2.data!.docs[index].data(),
                      messierWasViewed(
                          snap2.data!.docs[index].data(),
                          snap3.data!.docs.map((element) => element.data())),
                      snap.data!),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Returns null if location is unavailable, so rise/set times are omitted.
  Future<gps.LocationData?> _getLocation() async {
    gps.Location location = gps.Location();

    bool serviceEnabled;
    gps.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == gps.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != gps.PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }
}
