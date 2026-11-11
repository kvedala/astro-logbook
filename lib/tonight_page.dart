import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as gps;
import 'package:material_ui/material_ui.dart';

import 'services/tonight_service.dart';
import 'object_tile.dart';
import 'observation_actions.dart';
import 'weather_page.dart';
import 'wikipedia_page.dart';

String checklistObjectDocumentId(ObservingTarget target) =>
    'catalog_${target.isNgc ? 'ngc' : 'messier'}_${target.number}';

final _checklistObjectIdPattern = RegExp(r'^catalog_(messier|ngc)_\d+$');

bool isChecklistObjectDocumentId(String id) =>
    _checklistObjectIdPattern.hasMatch(id);

Future<void> setChecklistMembership(
  Transaction transaction,
  DocumentReference<Map<String, dynamic>> reference,
  ObservingTarget target,
  bool selected,
) async {
  if (!selected) {
    transaction.delete(reference);
    return;
  }
  final item = await transaction.get(reference);
  if (!item.exists) {
    transaction.set(reference, {
      'kind': 'catalogObject',
      'catalog': target.isNgc ? 'NGC' : 'Messier',
      'number': target.number,
      'title': '${target.isNgc ? 'NGC' : 'M'} ${target.number}',
      'value': false,
    });
  }
}

class TonightPage extends StatefulWidget {
  final Future<gps.LocationData> Function()? locationProvider;
  final Future<gps.LocationData?> Function()? lastKnownLocationProvider;
  final Stream<List<ObservingTarget>> Function()? catalogProvider;
  final Stream<List<Map<String, dynamic>>> Function()? observationsProvider;
  final Stream<Set<String>> Function()? checklistProvider;
  final Future<void> Function(ObservingTarget target, bool selected)?
  checklistUpdater;
  final Future<List<ObservingTarget>?> Function() Function()? ngcPageSource;
  final DateTime Function()? clock;

  const TonightPage({
    super.key,
    this.locationProvider,
    this.lastKnownLocationProvider,
    this.catalogProvider,
    this.observationsProvider,
    this.checklistProvider,
    this.checklistUpdater,
    this.ngcPageSource,
    this.clock,
  });

  @override
  State<TonightPage> createState() => _TonightPageState();
}

class _TonightPageState extends State<TonightPage> {
  late Future<gps.LocationData> _location;
  late Future<gps.LocationData?> _lastKnownLocation;
  Stream<List<ObservingTarget>>? _catalog;
  Stream<List<Map<String, dynamic>>>? _observations;
  Stream<Set<String>>? _checklist;
  final Set<String> _pendingChecklistIds = {};
  Timer? _nightTimer;
  DateTime? _nextNightUpdate;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _catalog = null;
    _location =
        widget.locationProvider?.call() ?? WeatherPage.getCurrentPosition;
    _lastKnownLocation =
        widget.lastKnownLocationProvider?.call() ??
        (widget.locationProvider == null
            ? WeatherPage.lastKnownPosition
            : Future.value(null));
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

  Stream<List<ObservingTarget>> _loadCatalog() => FirebaseFirestore.instance
      .collection('messier')
      .orderBy('number')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => ObservingTarget.fromMessierJson(doc.data()))
            .toList(),
      );

  Stream<List<Map<String, dynamic>>> _loadObservations() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in to see observation status.');
    }
    yield* FirebaseFirestore.instance
        .collection('users/$uid/observations')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<Set<String>> _loadChecklist() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in to manage your tonight checklist.');
    }
    yield* FirebaseFirestore.instance
        .collection('users/$uid/checklist')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => isChecklistObjectDocumentId(doc.id))
              .map((doc) => doc.id)
              .toSet(),
        );
  }

  Future<void> _setChecklist(ObservingTarget target, bool selected) async {
    final id = checklistObjectDocumentId(target);
    if (_pendingChecklistIds.contains(id)) return;
    setState(() => _pendingChecklistIds.add(id));
    try {
      if (widget.checklistUpdater case final updater?) {
        await updater(target, selected);
      } else {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          throw StateError('Sign in to manage your tonight checklist.');
        }
        final reference = FirebaseFirestore.instance
            .collection('users/$uid/checklist')
            .doc(id);
        await FirebaseFirestore.instance.runTransaction(
          (transaction) =>
              setChecklistMembership(transaction, reference, target, selected),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update tonight checklist: $error')),
      );
    } finally {
      if (mounted) setState(() => _pendingChecklistIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogStream = _catalog ??=
        (widget.catalogProvider ?? _loadCatalog)();
    final observations = _observations ??=
        (widget.observationsProvider ?? _loadObservations)();
    final checklist = _checklist ??=
        (widget.checklistProvider ?? _loadChecklist)();
    return StreamBuilder<Set<String>>(
      stream: checklist,
      builder: (context, checklistSnapshot) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: observations,
        builder: (context, observationSnapshot) => StreamBuilder<List<ObservingTarget>>(
          key: ObjectKey(catalogStream),
          stream: catalogStream,
          builder: (context, catalog) {
            return FutureBuilder<gps.LocationData?>(
              future: _lastKnownLocation,
              builder: (context, lastKnown) => FutureBuilder<gps.LocationData>(
                future: _location,
                builder: (context, location) {
                  final pending =
                      location.connectionState != ConnectionState.done;
                  final now = widget.clock?.call() ?? DateTime.now();
                  final cached = lastKnown.data;
                  final timestamp = cached?.time;
                  final age = timestamp == null || !timestamp.isFinite
                      ? null
                      : now.millisecondsSinceEpoch - timestamp;
                  final recent =
                      cached != null &&
                      cached.latitude.isFinite &&
                      cached.longitude.isFinite &&
                      cached.latitude.abs() <= 90 &&
                      cached.longitude.abs() <= 180 &&
                      age != null &&
                      age >= 0 &&
                      age <= const Duration(minutes: 10).inMilliseconds;
                  if (pending && !recent) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const Text('Getting location...'),
                          if (lastKnown.hasError)
                            Text(
                              'Could not get last known location: ${lastKnown.error}',
                            ),
                        ],
                      ),
                    );
                  }
                  if (!pending && (location.hasError || !location.hasData)) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Could not get location: ${location.error ?? "No location available"}',
                          ),
                          TextButton(
                            onPressed: () => setState(_refresh),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final position = pending ? cached! : location.data!;
                  final sky = TonightSky(
                    position.latitude,
                    position.longitude,
                    now,
                  );
                  _scheduleNightUpdate(sky, now);
                  if (catalog.hasError || !catalog.hasData) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _TonightHeader(
                          sky: sky,
                          onRefresh: () => setState(_refresh),
                          locationPending: pending,
                        ),
                        if (catalog.hasError)
                          Text(
                            'Could not load Messier catalog: ${catalog.error}',
                          )
                        else
                          const Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                Text('Loading catalog...'),
                              ],
                            ),
                          ),
                      ],
                    );
                  }
                  return TonightResults(
                    sky: sky,
                    locationPending: pending,
                    targets: catalog.data!,
                    checklistObjectIds: checklistSnapshot.data,
                    checklistError: checklistSnapshot.error,
                    onRetryChecklist: () => setState(() => _checklist = null),
                    pendingChecklistIds: _pendingChecklistIds,
                    onSetChecklist: _setChecklist,
                    observations: observationSnapshot.hasError
                        ? null
                        : observationSnapshot.data,
                    observationsError: observationSnapshot.error,
                    onRetryObservations: () =>
                        setState(() => _observations = null),
                    ngcPageSource:
                        widget.ngcPageSource ?? () => _NgcPages().next,
                    onRefresh: () => setState(_refresh),
                    onOpenObject: (target) => target.isNgc
                        ? openNgcWikipedia(context, target.number)
                        : openMessierWikipedia(context, target.number),
                    onOpenObservations: (target, viewed) {
                      if (!viewed) {
                        addTargetObservation(context, target);
                        return;
                      }
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sign in to see your observations.'),
                          ),
                        );
                        return;
                      }
                      openTargetObservations(
                        context,
                        target,
                        FirebaseFirestore.instance.collection(
                          'users/$uid/observations',
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NgcPages {
  QueryDocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _missingMagnitudes = false;
  bool _done = false;

  Future<List<ObservingTarget>?> next() async {
    if (_done) return null;
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('ngc')
        .orderBy(_missingMagnitudes ? 'number' : 'magnitude')
        .limit(80);
    if (_cursor != null) query = query.startAfterDocument(_cursor!);
    final snapshot = await query.get(const GetOptions(source: Source.server));
    final targets = snapshot.docs
        .map((doc) => ObservingTarget.fromNgcJson(doc.data()))
        .where((target) => hasKnownMagnitude(target) != _missingMagnitudes)
        .toList();
    if (snapshot.docs.isNotEmpty) _cursor = snapshot.docs.last;
    if (snapshot.docs.length < 80) {
      if (_missingMagnitudes) {
        _done = true;
      } else {
        _missingMagnitudes = true;
        _cursor = null;
      }
    }
    return targets;
  }
}

class _TonightHeader extends StatelessWidget {
  final TonightSky sky;
  final VoidCallback onRefresh;
  final bool locationPending;

  const _TonightHeader({
    required this.sky,
    required this.onRefresh,
    required this.locationPending,
  });

  String _time(DateTime time) => DateFormat('EEE HH:mm').format(time);

  String _events(List<SkyEvent> events, bool rising) {
    final times = events.where((event) => event.rising == rising);
    return times.isEmpty
        ? 'None this observing night'
        : times.map((e) => _time(e.time)).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final darkText = sky.darkness.isEmpty
        ? 'No astronomical darkness this observing night'
        : sky.darkness
              .map((d) => '${_time(d.start)}–${_time(d.end)}')
              .join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'What’s visible tonight?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Refresh location and times',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        Text(
          'Observing night: ${DateFormat('EEE, MMM d').format(sky.start)} – '
          '${DateFormat('EEE, MMM d').format(sky.end)} (local time)',
        ),
        if (locationPending)
          const Text(
            'Using a recent location while updating GPS; results may change.',
          ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Astronomical darkness: $darkText',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text('Sunset: ${_events(sky.sunEvents, false)}'),
                    Text('Sunrise: ${_events(sky.sunEvents, true)}'),
                    Text('Moonrise: ${_events(sky.moonEvents, true)}'),
                    Text('Moonset: ${_events(sky.moonEvents, false)}'),
                    Text(
                      'Moon illuminated: ${(sky.moonIllumination(sky.start.add(const Duration(hours: 12))) * 100).round()}% (near midnight)',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('About visibility'),
          children: [
            Text(
              'Visible times are when an object is above the horizon during astronomical darkness. Best time is its highest altitude in darkness. Objects near the horizon may be difficult to see. Moonlight, light pollution, weather, equipment and surface brightness affect visibility; magnitude alone does not determine darkness. Times are approximate.',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Visible Messier and NGC objects',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'Brightest first; objects without magnitude are listed last.',
        ),
      ],
    );
  }
}

class TonightResults extends StatefulWidget {
  final TonightSky sky;
  final bool locationPending;
  final List<ObservingTarget> targets;
  final Set<String>? checklistObjectIds;
  final Object? checklistError;
  final VoidCallback? onRetryChecklist;
  final Set<String> pendingChecklistIds;
  final void Function(ObservingTarget target, bool selected)? onSetChecklist;
  final VoidCallback onRefresh;
  final void Function(ObservingTarget target) onOpenObject;
  final void Function(ObservingTarget target, bool viewed)? onOpenObservations;
  final List<Map<String, dynamic>>? observations;
  final Object? observationsError;
  final VoidCallback? onRetryObservations;
  final Future<List<ObservingTarget>?> Function() Function() ngcPageSource;

  const TonightResults({
    super.key,
    required this.sky,
    this.locationPending = false,
    required this.targets,
    this.checklistObjectIds,
    this.checklistError,
    this.onRetryChecklist,
    this.pendingChecklistIds = const {},
    this.onSetChecklist,
    required this.onRefresh,
    required this.onOpenObject,
    this.onOpenObservations,
    this.observations,
    this.observationsError,
    this.onRetryObservations,
    required this.ngcPageSource,
  });

  @override
  State<TonightResults> createState() => _TonightResultsState();
}

class _TonightResultsState extends State<TonightResults> {
  late ObservingPager _pager;
  final ScrollController _scroll = ScrollController();
  bool _loading = false;
  Object? _error;
  int _generation = 0;
  bool _hasPager = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _reset();
  }

  @override
  void didUpdateWidget(TonightResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sky.start != widget.sky.start ||
        oldWidget.sky.latitude != widget.sky.latitude ||
        oldWidget.sky.longitude != widget.sky.longitude ||
        oldWidget.targets != widget.targets) {
      _reset();
    }
  }

  void _reset() {
    _generation++;
    if (_hasPager) _pager.cancel();
    _pager = ObservingPager(widget.sky, widget.targets, widget.ngcPageSource());
    _hasPager = true;
    _loading = false;
    _error = null;
    if (widget.sky.darkness.isEmpty) {
      _pager.done = true;
    } else {
      _loadMore();
    }
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 500) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || _pager.done || _error != null) return;
    final generation = _generation;
    final pager = _pager;
    setState(() => _loading = true);
    try {
      await pager.loadMore();
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && generation == _generation) _onScroll();
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _pager.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sky = widget.sky;
    final visible = _pager.results;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: visible.length + 1 + (!_pager.done || _error != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TonightHeader(
                sky: sky,
                onRefresh: widget.onRefresh,
                locationPending: widget.locationPending,
              ),
              if (widget.observationsError != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Could not load observations: ${widget.observationsError}',
                    ),
                    if (widget.onRetryObservations != null)
                      TextButton(
                        onPressed: widget.onRetryObservations,
                        child: const Text('Retry observations'),
                      ),
                  ],
                ),
              if (widget.checklistError != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Could not load checklist: ${widget.checklistError}'),
                    if (widget.onRetryChecklist != null)
                      TextButton(
                        onPressed: widget.onRetryChecklist,
                        child: const Text('Retry checklist'),
                      ),
                  ],
                ),
              if (visible.isEmpty && _pager.done)
                Text(
                  sky.darkness.isEmpty
                      ? 'No objects are listed because the sky does not reach astronomical darkness.'
                      : 'No catalog objects are above the horizon during astronomical darkness.',
                ),
            ],
          );
        }
        if (index > visible.length) {
          if (_error != null) {
            return Column(
              children: [
                Text('Could not load NGC catalog: $_error'),
                TextButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _loadMore();
                  },
                  child: const Text('Retry'),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final item = visible[index - 1];
        final target = item.target;
        final name = '${target.isNgc ? 'NGC' : 'M'} ${target.number}';
        final viewed = widget.observations == null
            ? null
            : targetWasViewed(target, widget.observations!);
        final checklistId = checklistObjectDocumentId(target);
        final checklistSelected = widget.checklistObjectIds?.contains(
          checklistId,
        );
        return ObjectTile(
          name: name,
          title: target.type.trim().isEmpty ? name : '$name · ${target.type}',
          details: [
            if (!target.isNgc && target.ngcNumbers.isNotEmpty)
              target.ngcNumbers.map((n) => 'NGC $n').join(', '),
            ?target.constellation,
            if (hasKnownMagnitude(target)) 'Magnitude ${target.magnitude}',
          ].join(' · '),
          visibilityLabel: 'Visible in darkness tonight',
          visibility: item,
          viewed: viewed,
          checklistSelected: checklistSelected,
          checklistUpdating: widget.pendingChecklistIds.contains(checklistId),
          onOpenObject: () => widget.onOpenObject(target),
          onOpenObservations:
              viewed == null || widget.onOpenObservations == null
              ? null
              : () => widget.onOpenObservations!(target, viewed),
          onToggleChecklist: widget.onSetChecklist == null
              ? null
              : () => widget.onSetChecklist!(target, !checklistSelected!),
        );
      },
    );
  }
}
