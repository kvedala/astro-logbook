import 'package:astro_log/equipment.dart';
import 'package:astro_log/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EquipmentGallery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userID = FirebaseAuth.instance.currentUser.uid;
    return Column(
      children: [
        StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users/$userID/equipments')
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snap) =>
              !snap.hasData
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: snap.data.size,
                      itemBuilder: (context, index) => Dismissible(
                        key: Key(snap.data.docs[index].id),
                        background: Container(color: Colors.red.withAlpha(100)),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10)),
                          child: Equipment.fromReference(
                            snap.data.docs[index].reference,
                            onTap: () => Equipment.addEquipment(context,
                                inData: snap.data.docs[index].data(),
                                reference: snap.data.docs[index].reference),
                          ),
                        ),
                        confirmDismiss: (dir) async {
                          final doc = await FirebaseFirestore.instance
                              .collection('users/$userID/observations')
                              .where('equipment',
                                  isEqualTo: snap.data.docs[index].reference)
                              .limit(1)
                              .get();
                          if (doc.size == 0) return confirmDeleteTile(context);

                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              Future.delayed(Duration(seconds: 2),
                                  () => Navigator.pop(context));
                              return Text(
                                "Cannot delete. Equipment is being referenced "
                                "in an observation.",
                                style: TextStyle(fontSize: 20),
                              );
                            },
                          );

                          return false;
                        },
                        onDismissed: (dir) async {
                          FirebaseFirestore.instance
                              .doc(snap.data.docs[index].reference.path)
                              .delete();
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
