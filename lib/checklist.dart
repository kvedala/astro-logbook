import 'package:astro_log/checklist_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'utils.dart';

/// Body of checklist tab
class CheckList extends StatelessWidget {
  /// list of checklist items
  final List<CheckListItem> items = [];

  /// Body of checklist tab for the user
  CheckList({Key key}) : super(key: key);

  /// Add a new checklist item to the DB
  static void addCheckListItem(BuildContext context) async {
    final textController = TextEditingController();

    bool add = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add checklist item"),
        content: TextField(
          controller: textController,
          maxLength: 5,
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: Icon(Icons.done),
            label: Text("Add"),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: Icon(Icons.cancel),
            label: Text("Cancel"),
          ),
        ],
      ),
    );
    if (add) {
      FirebaseFirestore.instance
          .collection(
              'users/${FirebaseAuth.instance.currentUser.uid}/checklist')
          .add({
        'title': textController.text,
        'value': false,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(DateTime.now().yMMMd, style: TextStyle(fontSize: 20)),
      // ]),
      Form(
        child: Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(
                    'users/${FirebaseAuth.instance.currentUser.uid}/checklist')
                .snapshots(),
            builder: (context, snap) {
              items.clear();
              items.addAll(snap.data.docs.expand((doc) => [
                    CheckListItem(
                      doc.get('title'),
                      reference: doc.reference,
                      initialValue: doc.get('value'),
                    ),
                  ]));
              return !snap.hasData
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: snap.data.size,
                      itemBuilder: (context, index) => Dismissible(
                        key: Key(snap.data.docs[index].toString()),
                        background: Container(color: Colors.red),
                        confirmDismiss: (dir) => confirmDeleteTile(context),
                        child: items[index],
                        onDismissed: (dir) async =>
                            await snap.data.docs[index].reference.delete(),
                      ),
                    );
            },
          ),
        ),
      ),
      ElevatedButton.icon(
        icon: Icon(Icons.save_alt_rounded),
        label: Text("Save Checklist"),
        onPressed: () async {
          final batch = FirebaseFirestore.instance.batch();
          items.forEach((item) {
            if (item.hasChanged) {
              batch.set(item.reference, item.data);
              print("${item.title}: change-");
            }
          });
          await batch.commit();
        },
      ),
    ]);
  }
}
