import 'package:astro_log/add_observation.dart';
import 'package:astro_log/gallary_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils.dart';

/// Page to display the observations as a gallery
class ObservationsGallary extends StatefulWidget {
  const ObservationsGallary({Key key}) : super(key: key);

  _ObservationsGallaryState createState() => _ObservationsGallaryState();
}

class _ObservationsGallaryState extends State<ObservationsGallary> {
  final ngcSearchController = TextEditingController();
  final messierSearchController = TextEditingController();
  final stringSearchController = TextEditingController();
  final dateSearchController = TextEditingController();
  DateTimeRange dateSearchRange;
  bool clickOnClear = false;

  // @override
  // void initState() {
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(children: [
      Container(
        padding: EdgeInsets.symmetric(vertical: 0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messierSearchController,
                keyboardType: TextInputType.numberWithOptions(
                    decimal: false, signed: false),
                decoration: InputDecoration(
                  // prefixIcon: Icon(Icons.search_rounded, color: Colors.red),
                  labelText: "Search Messier",
                  suffix: IconButton(
                    padding: EdgeInsets.all(0),
                    iconSize: 20,
                    icon: Icon(Icons.clear_rounded),
                    onPressed: () =>
                        setState(() => messierSearchController.clear()),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            Expanded(
              child: TextField(
                controller: ngcSearchController,
                keyboardType: TextInputType.numberWithOptions(
                    decimal: false, signed: false),
                decoration: InputDecoration(
                  // prefixIcon: Icon(Icons.search_rounded, color: Colors.red),
                  labelText: "Search NGC",
                  suffix: IconButton(
                    padding: EdgeInsets.all(0),
                    iconSize: 20,
                    icon: Icon(Icons.clear_rounded),
                    onPressed: () =>
                        setState(() => ngcSearchController.clear()),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            Expanded(
              child: TextField(
                controller: dateSearchController,
                keyboardType: TextInputType.datetime,
                readOnly: true,
                decoration: InputDecoration(
                  // prefixIcon: Icon(Icons.search_rounded, color: Colors.red),
                  labelText: "Search by Date",
                  suffix: IconButton(
                    padding: EdgeInsets.all(0),
                    iconSize: 20,
                    icon: Icon(Icons.clear_rounded),
                    onPressed: () => setState(() {
                      clickOnClear = true;
                      dateSearchController.clear();
                      dateSearchRange = null;
                    }),
                  ),
                ),
                onChanged: (value) => setState(() {}),
                onTap: () async {
                  if (clickOnClear) {
                    clickOnClear = false;
                    return;
                  }
                  dateSearchRange = await showDateRangePicker(
                    context: context,
                    initialDateRange: dateSearchRange ?? null,
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                    fieldStartLabelText: "From date",
                    fieldEndLabelText: "End date",
                  );
                  if (dateSearchRange != null)
                    setState(() => dateSearchController.text =
                        dateSearchRange.start.yMMMd +
                            " - " +
                            dateSearchRange.end.yMMMd);
                  else
                    setState(() => dateSearchController.clear());
                },
              ),
            ),
          ],
        ),
      ),
      StreamBuilder<QuerySnapshot>(
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
                          // itemCount: snap.data.docs.length,
                          itemBuilder: (context, index) => index <
                                  snap.data.docs.length
                              ? GallaryTile.fromObservation(
                                  ObservationData.fromJSON(
                                    snap.data.docs[index].data(),
                                  ),
                                  reference: snap.data.docs[index].reference,
                                )
                              : null,
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

    if (dateSearchRange != null) {
      return firestore
          .collection('users/' + auth.currentUser.uid + '/observations')
          .where('dateTime', isGreaterThanOrEqualTo: dateSearchRange.start)
          .where('dateTime', isLessThanOrEqualTo: dateSearchRange.end)
          // .orderBy('dateTime', descending: true)
          .snapshots(includeMetadataChanges: true);
    } else if (messierSearchController.text.isNotEmpty ||
        ngcSearchController.text.isNotEmpty)
      return firestore
          .collection('users/' + auth.currentUser.uid + '/observations')
          .where('messier',
              isEqualTo: int.tryParse(messierSearchController.text))
          .where('ngc', isEqualTo: int.tryParse(ngcSearchController.text))
          // .where('title', arrayContains: stringSearchController.text)
          // .where('notes', arrayContains: stringSearchController)
          // .orderBy('dateTime', descending: true)
          .snapshots(includeMetadataChanges: true);
    else
      return firestore
          .collection('users/' + auth.currentUser.uid + '/observations')
          .orderBy('dateTime', descending: true)
          .snapshots(includeMetadataChanges: true);
    // .map<List<ObservationData>>(
    //     (snapshot) => snapshot.docs.map<ObservationData>((doc) {
    //           return ObservationData.fromJSON(doc.data());
    //         }).toList());
  }
}

/// Page to display the observations as a gallery
class PhotographyGallary extends StatelessWidget {
  const PhotographyGallary({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("To be implemented...."),
    );
  }
}
