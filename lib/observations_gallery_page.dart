import 'package:astro_log/add_observation.dart';
import 'package:astro_log/gallary_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Page to display the observations as a gallery
class ObservationsGallary extends StatefulWidget {
  _ObservationsGallaryState createState() => _ObservationsGallaryState();
}

class _ObservationsGallaryState extends State<ObservationsGallary> {
  final ngcSearchController = TextEditingController();
  final messierSearchController = TextEditingController();
  final stringSearchController = TextEditingController();
  final dateSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(children: [
      Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messierSearchController,
                keyboardType: TextInputType.numberWithOptions(
                    decimal: false, signed: false),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.red),
                  labelText: "Search Messier",
                  suffix: SizedBox(
                    height: 15,
                    width: 15,
                    child: IconButton(
                      padding: EdgeInsets.all(0),
                      icon: Icon(Icons.clear_rounded, size: 15),
                      onPressed: () =>
                          setState(() => messierSearchController.clear()),
                    ),
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
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.red),
                  labelText: "Search NGC",
                  suffix: SizedBox(
                    height: 15,
                    width: 15,
                    child: IconButton(
                      padding: EdgeInsets.all(0),
                      icon: Icon(Icons.clear_rounded, size: 15),
                      onPressed: () =>
                          setState(() => ngcSearchController.clear()),
                    ),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            Expanded(
              child: TextField(
                controller: dateSearchController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.red),
                  labelText: "Search by Date",
                  suffix: SizedBox(
                    height: 15,
                    width: 15,
                    child: IconButton(
                      padding: EdgeInsets.all(0),
                      icon: Icon(Icons.clear_rounded, size: 15),
                      onPressed: () =>
                          setState(() => dateSearchController.clear()),
                    ),
                  ),
                ),
                onChanged: (value) => setState(() {}),
                onTap: () async {
                  DateTime initialDate;
                  try {
                    initialDate =
                        DateFormat.yMMMd().parse(dateSearchController.text);
                  } catch (e) {
                    initialDate = DateTime.now();
                  }
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    fieldLabelText: "Search by date",
                  );
                  if (selectedDate != null)
                    setState(() => dateSearchController.text =
                        DateFormat.yMMMd().format(selectedDate));
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
              case ConnectionState.waiting:
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
                          itemCount: snap.data.docs.length,
                          itemBuilder: (context, index) =>
                              GallaryTile.fromObservation(
                            ObservationData.fromJSON(
                                snap.data.docs[index].data()),
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

    if (dateSearchController.text.isNotEmpty) {
      DateTime startDate;
      try {
        startDate = DateFormat.yMMMd().parse(dateSearchController.text);
      } catch (e) {
        startDate = null;
      }
      if (startDate == null)
        return firestore
            .collection('users/' + auth.currentUser.uid + '/observations')
            .where('messier',
                isEqualTo: int.tryParse(messierSearchController.text))
            .where('ngc', isEqualTo: int.tryParse(ngcSearchController.text))
            // .where('title', arrayContains: stringSearchController.text)
            // .where('notes', arrayContains: stringSearchController)
            // .orderBy('dateTime', descending: true)
            .snapshots(includeMetadataChanges: true);
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      final endDate =
          DateTime(startDate.year, startDate.month, startDate.day + 1);
      return firestore
          .collection('users/' + auth.currentUser.uid + '/observations')
          .where('dateTime', isGreaterThanOrEqualTo: startDate)
          .where('dateTime', isLessThanOrEqualTo: endDate)
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("To be implemented...."),
    );
  }
}
