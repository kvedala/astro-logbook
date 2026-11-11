import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart' as gps;
import 'package:material_ui/material_ui.dart';

import 'object_tile.dart';
import 'observation_actions.dart';
import 'objects.dart';
import 'services/tonight_service.dart';
import 'wikipedia_page.dart';

bool messierWasViewed(
  Map<String, dynamic> object,
  Iterable<Map<String, dynamic>> observations,
) {
  return observations.any(
    (observation) => matchesCatalogObservation(
      number: object['number'] as int,
      isNgc: false,
      linkedNumbers: (object['ngcNumbers'] as List<dynamic>? ?? [])
          .whereType<int>(),
      observation: observation,
    ),
  );
}

class ListOfObjects extends StatefulWidget {
  const ListOfObjects({super.key});

  @override
  State<ListOfObjects> createState() => _ListOfObjectsState();
}

class _ListOfObjectsState extends State<ListOfObjects> {
  late Future<gps.LocationData?> _location;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _catalog;
  CollectionReference<Map<String, dynamic>>? _observationsCollection;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _observations;
  Timer? _nightTimer;
  DateTime? _nextNightUpdate;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logScreenView(
      screenName: 'List of Messier Objects',
    );
    _location = _getLocation();
    _catalog = FirebaseFirestore.instance
        .collection('messier')
        .orderBy('number')
        .snapshots();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _observationsCollection = FirebaseFirestore.instance.collection(
        'users/$uid/observations',
      );
      _observations = _observationsCollection!.snapshots();
    }
  }

  @override
  void dispose() {
    _nightTimer?.cancel();
    super.dispose();
  }

  void _scheduleNightUpdate(TonightSky sky, DateTime now) {
    final futureDarkness = sky.darkness.where(
      (interval) => interval.end.isAfter(now),
    );
    final next = futureDarkness.isEmpty ? sky.end : futureDarkness.last.end;
    if (_nextNightUpdate == next && _nightTimer?.isActive == true) return;
    _nightTimer?.cancel();
    _nextNightUpdate = next;
    _nightTimer = Timer(next.difference(now), () {
      if (mounted) setState(() => _nextNightUpdate = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final observationsStream = _observations;
    if (observationsStream == null) {
      return const Center(child: Text('Sign in to see your observations.'));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _catalog,
      builder: (context, catalog) {
        if (catalog.hasError) {
          return Center(
            child: Text('Could not load Messier catalog: ${catalog.error}'),
          );
        }
        if (!catalog.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: observationsStream,
          builder: (context, observations) {
            if (observations.hasError) {
              return Center(
                child: Text(
                  'Could not load observations: ${observations.error}',
                ),
              );
            }
            if (!observations.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return FutureBuilder<gps.LocationData?>(
              future: _location,
              builder: (context, location) {
                final position = location.data;
                final validPosition =
                    position != null &&
                    position.latitude.isFinite &&
                    position.longitude.isFinite &&
                    position.latitude.abs() <= 90 &&
                    position.longitude.abs() <= 180;
                final now = DateTime.now();
                final sky = validPosition
                    ? TonightSky(position.latitude, position.longitude, now)
                    : null;
                if (sky != null) _scheduleNightUpdate(sky, now);
                final docs = catalog.data!.docs;
                final logs = observations.data!.docs;
                return ListView.builder(
                  itemCount: docs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Messier objects',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Text(
                              'Tap an object for Wikipedia; tap a status icon for details or observations.',
                            ),
                            if (location.connectionState !=
                                ConnectionState.done)
                              const Text('Getting location for visibility...')
                            else if (sky == null) ...[
                              Text(
                                location.hasError
                                    ? 'Visibility unavailable: ${location.error}'
                                    : 'Visibility unavailable: no valid location.',
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _location = _getLocation()),
                                child: const Text('Retry location'),
                              ),
                            ],
                            if (docs.isEmpty)
                              const Text('No Messier objects available.'),
                          ],
                        ),
                      );
                    }
                    final data = docs[index - 1].data();
                    final object = Messier.fromJSON(data);
                    final target = ObservingTarget.fromMessierJson(data);
                    final viewed = messierWasViewed(
                      data,
                      logs.map((doc) => doc.data()),
                    );
                    return MessierListTile(
                      object: object,
                      viewed: viewed,
                      sky: sky,
                      onOpenObject: () =>
                          openMessierWikipedia(context, object.id),
                      onOpenObservations: () {
                        if (!viewed) {
                          addTargetObservation(context, target);
                          return;
                        }
                        openTargetObservations(
                          context,
                          target,
                          _observationsCollection!,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<gps.LocationData?> _getLocation() async {
    final location = gps.Location();
    if (!await location.serviceEnabled() && !await location.requestService()) {
      return null;
    }
    var permission = await location.hasPermission();
    if (permission == gps.PermissionStatus.denied) {
      permission = await location.requestPermission();
    }
    if (permission != gps.PermissionStatus.granted &&
        permission != gps.PermissionStatus.grantedLimited) {
      return null;
    }
    return location.getLocation();
  }
}

class MessierListTile extends StatelessWidget {
  final Messier object;
  final bool viewed;
  final TonightSky? sky;
  final VoidCallback onOpenObject;
  final VoidCallback onOpenObservations;

  const MessierListTile({
    super.key,
    required this.object,
    required this.viewed,
    required this.sky,
    required this.onOpenObject,
    required this.onOpenObservations,
  });

  @override
  Widget build(BuildContext context) {
    final visibility = sky?.visibility(
      ObservingTarget(
        object.id,
        object.type,
        object.constellation,
        object.magnitude,
        object.ra,
        object.dec,
        object.ngcNumbers,
      ),
    );
    final visibilityLabel = sky == null
        ? 'Visibility unavailable'
        : sky!.darkness.isEmpty
        ? 'No astronomical darkness tonight'
        : visibility == null
        ? 'Not visible in darkness tonight'
        : 'Visible in darkness tonight';
    return ObjectTile(
      name: 'M ${object.id}',
      title: 'M ${object.id} · ${object.type}',
      details: [
        if (object.ngcNumbers.isNotEmpty)
          object.ngcNumbers.map((n) => 'NGC $n').join(', '),
        'RA: ${object.ra}',
        'DEC: ${object.dec}',
        ?object.difficulty,
        if (object.magnitude != null) 'Mag ${object.magnitude}',
      ].join(' · '),
      visibilityLabel: visibilityLabel,
      visibility: visibility,
      visibilityKnown: sky != null,
      viewed: viewed,
      onOpenObject: onOpenObject,
      onOpenObservations: onOpenObservations,
    );
  }
}
