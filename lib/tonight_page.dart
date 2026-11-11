import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as gps;
import 'package:material_ui/material_ui.dart';

import 'services/tonight_service.dart';
import 'weather_page.dart';
import 'wikipedia_page.dart';

class TonightPage extends StatefulWidget {
  final Future<gps.LocationData> Function()? locationProvider;
  final Future<gps.LocationData?> Function()? lastKnownLocationProvider;
  final Stream<List<ObservingTarget>> Function()? catalogProvider;
  final Future<List<ObservingTarget>?> Function() Function()? ngcPageSource;
  final DateTime Function()? clock;

  const TonightPage({
    super.key,
    this.locationProvider,
    this.lastKnownLocationProvider,
    this.catalogProvider,
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

  @override
  Widget build(BuildContext context) {
    final catalogStream = _catalog ??=
        (widget.catalogProvider ?? _loadCatalog)();
    return StreamBuilder<List<ObservingTarget>>(
      key: ObjectKey(catalogStream),
      stream: catalogStream,
      builder: (context, catalog) {
        return FutureBuilder<gps.LocationData?>(
          future: _lastKnownLocation,
          builder: (context, lastKnown) => FutureBuilder<gps.LocationData>(
            future: _location,
            builder: (context, location) {
              final pending = location.connectionState != ConnectionState.done;
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
                      Text('Could not load Messier catalog: ${catalog.error}')
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
                ngcPageSource: widget.ngcPageSource ?? () => _NgcPages().next,
                onRefresh: () => setState(_refresh),
                onOpenObject: (target) => target.isNgc
                    ? openNgcWikipedia(context, target.number)
                    : openMessierWikipedia(context, target.number),
              );
            },
          ),
        );
      },
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
  final VoidCallback onRefresh;
  final void Function(ObservingTarget target) onOpenObject;
  final Future<List<ObservingTarget>?> Function() Function() ngcPageSource;

  const TonightResults({
    super.key,
    required this.sky,
    this.locationPending = false,
    required this.targets,
    required this.onRefresh,
    required this.onOpenObject,
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

  String _time(DateTime time) => DateFormat('EEE HH:mm').format(time);

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
        final title = target.isNgc
            ? 'NGC ${target.number}'
            : 'M ${target.number}${target.ngcNumbers.isEmpty ? '' : ' (${target.ngcNumbers.map((n) => 'NGC $n').join(', ')})'}';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            target.type.trim().isEmpty ? title : '$title · ${target.type}',
          ),
          subtitle: Text(
            [
              [
                if (item.target.constellation != null)
                  item.target.constellation!,
                if (hasKnownMagnitude(item.target))
                  'Magnitude ${item.target.magnitude}',
              ].join(' · '),
              'Visible in darkness: ${item.intervals.map((interval) => '${_time(interval.start)}–${_time(interval.end)}').join(', ')}',
              [
                'Best ${_time(item.bestTime)} · ${item.altitudeDegrees.round()}° high',
                if (item.moonUp) 'Moon up at best time',
              ].join(' · '),
            ].where((line) => line.isNotEmpty).join('\n'),
          ),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => widget.onOpenObject(target),
        );
      },
    );
  }
}
