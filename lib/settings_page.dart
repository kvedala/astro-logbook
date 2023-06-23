import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import 'generated/l10n.dart';

/// Page to display the observations as a gallery
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final collectionRoot = 'users/${FirebaseAuth.instance.currentUser!.uid}';

    return Column(mainAxisSize: MainAxisSize.max, children: [
      Expanded(
        child: Column(mainAxisSize: MainAxisSize.max, children: [
          Text(S.of(context).userStats,
              style: Theme.of(context).textTheme.headlineSmall),
          Table(children: [
            TableRow(children: [
              Text("${S.of(context).numberOfObservations}:",
                  style: Theme.of(context).textTheme.titleMedium),
              FutureBuilder<AggregateQuerySnapshot>(
                future: store
                    .collection('$collectionRoot/observations')
                    .count()
                    .get(),
                builder: (ctx, snap) =>
                    snap.connectionState == ConnectionState.waiting
                        ? const LinearProgressIndicator()
                        : Text(
                            snap.hasError
                                ? "Error: ${snap.error}"
                                : snap.data!.count.toString(),
                            style: Theme.of(context).textTheme.titleMedium),
              ),
            ]),
            TableRow(children: [
              Text("${S.of(context).numberOfEquipment}:",
                  style: Theme.of(context).textTheme.titleMedium),
              FutureBuilder<AggregateQuerySnapshot>(
                future: store
                    .collection('$collectionRoot/equipments')
                    .count()
                    .get(),
                builder: (ctx, snap) =>
                    snap.connectionState == ConnectionState.waiting
                        ? const LinearProgressIndicator()
                        : Text(
                            snap.hasError
                                ? "Error: ${snap.error}"
                                : snap.data!.count.toString(),
                            style: Theme.of(context).textTheme.titleMedium),
              ),
            ]),
          ]),
        ]),
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.person_remove),
        label: Text(S.of(context).deleteAccount),
        onPressed: () => showDialog<bool?>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Ionicons.alert_circle),
            title: Text(S.of(context).deleteAccount),
            content:
                Text(S.of(context).areYouSureYouWantToDeleteYourAccountThis),
            actions: [
              ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.done),
                  label: Text(S.of(context).delete)),
              ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  onPressed: () => Navigator.pop(context, false),
                  label: Text(S.of(context).cancel)),
            ],
          ),
        ).then((result) {
          if (result == null) return;
          if (!result) return;
          store.collection('$collectionRoot/deleted').add({
            'timestamp': DateTime.now(),
            'displayName': auth.currentUser!.displayName,
            'email': auth.currentUser!.email,
            'metadata': {
              'created': auth.currentUser!.metadata.creationTime,
              'lastSignedIn': auth.currentUser!.metadata.lastSignInTime,
            },
            'provider': auth.currentUser!.providerData
                .map((e) => {
                      'id': e.providerId,
                      'displayName': e.displayName,
                      'email': e.email,
                      'uid': e.uid,
                    })
                .toList(growable: false),
          }).then(
              (value) => auth.currentUser!.reload().then(
                  (_) => auth.currentUser!.delete().then(
                      (_) => Navigator.pushReplacementNamed(context, '/'),
                      onError: (e) => ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                              content: Text(e.toString().split("] ").last)))),
                  onError: (e) => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())))),
              onError: (e) => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString()))));
        }),
      )
    ]);
  }

  // Widget _futureDisplay(Future future, Builder builder) => FutureBuilder(builder: builder)
}
