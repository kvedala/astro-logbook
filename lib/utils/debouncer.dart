import 'dart:async';
import 'package:flutter/widgets.dart';

/// Delays work until calls to [run] have stopped for [milliseconds].
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    // Replacing the timer ensures only the most recently scheduled action runs.
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
