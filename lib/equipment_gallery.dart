import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'equipment.dart';
import 'generated/l10n.dart';
import 'utils.dart';

/// Widget to show a gallery of equipments and add as needed
class EquipmentGallery extends StatelessWidget {
  const EquipmentGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final userID = FirebaseAuth.instance.currentUser!.uid;
    return Column(
      children: [
        StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users/$userID/equipments')
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snap) =>
              !snap.hasData
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: snap.data!.size,
                      itemBuilder: (context, index) => Dismissible(
                        key: Key(snap.data!.docs[index].id),
                        background: Container(color: Colors.red.withAlpha(100)),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10)),
                          child: Equipment.fromReference(
                            snap.data!.docs[index].reference,
                            onTap: () => Equipment.addEquipment(context,
                                inData: snap.data!.docs[index].data()
                                    as Map<String, dynamic>?,
                                reference: snap.data!.docs[index].reference),
                          ),
                        ),
                        confirmDismiss: (dir) async {
                          return await FirebaseFirestore.instance
                              .collection('users/$userID/observations')
                              .where('equipment',
                                  isEqualTo: snap.data!.docs[index].reference)
                              .limit(1)
                              .get()
                              .then((doc) => doc.size == 0
                                  ? confirmDeleteTile(context)
                                  : null)
                              .then((ret) {
                            if (ret != null) return ret;

                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                Future.delayed(const Duration(seconds: 2),
                                    () => Navigator.pop(context));
                                return Text(
                                  S
                                      .of(context)
                                      .cannotDeleteEquipmentIsBeingReferencedInAnObservation,
                                  style: const TextStyle(fontSize: 20),
                                );
                              },
                            );

                            return false;
                          });
                        },
                        onDismissed: (dir) async {
                          FirebaseFirestore.instance
                              .doc(snap.data!.docs[index].reference.path)
                              .delete();
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
