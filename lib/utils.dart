import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Convert decimal degrees to string degree-minute-second format
String decimalDegreesToDMS(num numeric, String latOrLong) {
  bool isNegative = false;
  if (numeric < 0) {
    isNegative = true;
    numeric = -numeric;
  }
  int degree = numeric.toDouble().floor();
  int minute = ((numeric - degree) * 60).toDouble().floor();
  double seconds = (((numeric - degree).toDouble() * 60) - minute) * 60;

  return "$degree\xb0 $minute\' ${seconds.toStringAsFixed(1)}\" " +
      (latOrLong == 'lat'
          ? (isNegative ? "S" : "N")
          : (isNegative ? "W" : "E"));
}

extension CapExtension on String {
  /// convert first word to uppercacse
  String get inCaps => '${this[0].toUpperCase()}${this.substring(1)}';

  /// convert first letter of every word to uppercase
  String get capitalizeFirstofEach =>
      this.split(" ").map((str) => str.inCaps).join(" ");
}

extension CheckExtension on DateTime {
  /// Check if between [startDate] and [endDate]
  bool isBetween(DateTime startDate, DateTime endDate) =>
      this.isBefore(endDate) && this.isAfter(startDate);

  /// Extract the date from a [DateTime] instance
  DateTime get date => DateFormat.yMd().parse(DateFormat.yMd().format(this));

  /// Get [DateFormat.yMMMd] representation of the date
  String get yMMMd => DateFormat.yMMMd().format(this);

  /// Get [DateFormat.Hm] representation of the time
  String get hourMinute => DateFormat.Hm().format(this);
}

/// Modal dialog at bottom to confirm tile dimissal
///
/// Asks for confirmation when a [Dismissible] widget needs to be deleted.
Future<bool> confirmDeleteTile(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      builder: (context) => ButtonBar(
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.done_all_rounded),
            label: Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.cancel_rounded),
            label: Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
