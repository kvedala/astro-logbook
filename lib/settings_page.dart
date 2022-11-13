import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

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
          Text("User Stats", style: Theme.of(context).textTheme.headline5),
          Table(children: [
            TableRow(children: [
              Text("Number of Observations:",
                  style: Theme.of(context).textTheme.subtitle1),
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
                            style: Theme.of(context).textTheme.subtitle1),
              ),
            ]),
            TableRow(children: [
              Text("Number of Equipment:",
                  style: Theme.of(context).textTheme.subtitle1),
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
                            style: Theme.of(context).textTheme.subtitle1),
              ),
            ]),
          ]),
        ]),
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.person_remove),
        label: const Text("Delete Account"),
        onPressed: () => showDialog<bool?>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Ionicons.alert_circle),
            title: const Text("Delete Account"),
            content: const Text(
                "Are you sure you want to delete your account? This action cannot be undone."),
            actions: [
              ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.done),
                  label: const Text("Delete")),
              ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  onPressed: () => Navigator.pop(context, false),
                  label: const Text("Cancel")),
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
