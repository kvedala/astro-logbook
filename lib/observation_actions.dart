import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import 'add_observation.dart';
import 'gallary_tile.dart';
import 'models/observing_target.dart';
import 'models/observation_data.dart';

bool matchesCatalogObservation({
  required int number,
  required bool isNgc,
  required Iterable<int> linkedNumbers,
  required Map<String, dynamic> observation,
}) {
  final primary = isNgc ? 'ngc' : 'messier';
  final linked = isNgc ? 'messier' : 'ngc';
  return observation[primary] == number ||
      linkedNumbers.contains(observation[linked]);
}

bool targetWasViewed(
  ObservingTarget target,
  Iterable<Map<String, dynamic>> observations,
) => observations.any(
  (observation) => matchesCatalogObservation(
    number: target.number,
    isNgc: target.isNgc,
    linkedNumbers: target.isNgc ? target.messierNumbers : target.ngcNumbers,
    observation: observation,
  ),
);

void addTargetObservation(BuildContext context, ObservingTarget target) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AddObservationPage(
        messierNumber: target.isNgc ? null : target.number,
        ngcNumber: target.isNgc ? target.number : null,
      ),
    ),
  );
}

void openTargetObservations(
  BuildContext context,
  ObservingTarget target,
  CollectionReference<Map<String, dynamic>> collection,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _TargetObservationsPage(
        target: target,
        observations: collection.snapshots(),
      ),
    ),
  );
}

class _TargetObservationsPage extends StatelessWidget {
  final ObservingTarget target;
  final Stream<QuerySnapshot<Map<String, dynamic>>> observations;

  const _TargetObservationsPage({
    required this.target,
    required this.observations,
  });

  @override
  Widget build(BuildContext context) {
    final title = '${target.isNgc ? 'NGC' : 'M'} ${target.number}';
    return Scaffold(
      appBar: AppBar(title: Text('$title observations')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add observation',
        onPressed: () => addTargetObservation(context, target),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: observations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load observations: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs
              .where((doc) => targetWasViewed(target, [doc.data()]))
              .toList();
          if (docs.isEmpty) {
            return const Center(child: Text('No matching observations.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) => GallaryTile.fromObservation(
              ObservationData.fromJson(docs[index].data()),
              reference: docs[index].reference,
            ),
          );
        },
      ),
    );
  }
}
