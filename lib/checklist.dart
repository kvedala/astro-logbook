import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'generated/l10n.dart';
import 'utils.dart';
import 'checklist_item.dart';
import 'models/checklist_data.dart';

/// Body of checklist tab
class CheckList extends StatelessWidget {
  /// list of checklist items
  final List<CheckListItem> items = List<CheckListItem>.empty(growable: true);

  /// Body of checklist tab for the user
  CheckList({super.key});

  static Future<void> saveItems(
      WriteBatch batch, Iterable<CheckListItem> items) async {
    for (final item in items.where((item) => item.hasChanged)) {
      batch.update(item.reference!, {'value': item.data['value']});
    }
    await batch.commit();
  }

  /// Add a new checklist item to the DB
  static void addCheckListItem(BuildContext context) async {
    final textController = TextEditingController();

    final add = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.current.addChecklistItem),
        content: TextField(
          controller: textController,
          maxLines: 5,
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.done),
            label: Text(S.current.add),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.cancel),
            label: Text(S.current.cancel),
          ),
        ],
      ),
    );
    if (add ?? false) {
      FirebaseFirestore.instance
          .collection(
              'users/${FirebaseAuth.instance.currentUser!.uid}/checklist')
          .add(ChecklistData(title: textController.text, value: false).toJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(DateTime.now().yMMMd, style: const TextStyle(fontSize: 20)),
      // ]),
      Expanded(
        child: Form(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(
                    'users/${FirebaseAuth.instance.currentUser?.uid ?? ''}/checklist')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              items.clear();
              items.addAll(snap.data!.docs.map((doc) {
                final data = ChecklistData.fromJson({
                  'title': doc.get('title'),
                  'value': doc.get('value'),
                });
                return CheckListItem(
                  data.title,
                  reference: doc.reference,
                  initialValue: data.value,
                );
              }));
              return ListView.builder(
                itemCount: snap.data!.size,
                itemBuilder: (context, index) => Dismissible(
                  key: Key(snap.data!.docs[index].toString()),
                  background: Container(color: Colors.red),
                  confirmDismiss: (dir) => confirmDeleteTile(context),
                  child: items[index],
                  onDismissed: (dir) async =>
                      await snap.data!.docs[index].reference.delete(),
                ),
              );
            },
          ),
        ),
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.save_alt_rounded),
        label: Text(S.current.saveChecklist),
        onPressed: () async {
          try {
            await saveItems(FirebaseFirestore.instance.batch(), items);
          } catch (error) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not save checklist: $error')),
            );
          }
        },
      ),
    ]);
  }
}
