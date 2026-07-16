import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/observation_data.dart';

class PaginatedObservationList extends StatefulWidget {
  const PaginatedObservationList({super.key});

  @override
  State<PaginatedObservationList> createState() =>
      _PaginatedObservationListState();
}

class _PaginatedObservationListState extends State<PaginatedObservationList> {
  final ScrollController _scrollController = ScrollController();
  final List<ObservationData> _observations = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMoreData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    Query query = FirebaseFirestore.instance
        .collection(
          'users/${FirebaseAuth.instance.currentUser?.uid ?? ''}/observations',
        )
        .orderBy('dateTime', descending: true)
        .limit(_pageSize);
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      final newObservations = snapshot.docs
          .map(
            (doc) =>
                ObservationData.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
      setState(() {
        _observations.addAll(newObservations);
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _observations.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _observations.length) {
          final observation = _observations[index];
          return ListTile(
            title: Text(observation.title ?? 'Untitled'),
            subtitle: Text(observation.dateTime?.toString() ?? ''),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
