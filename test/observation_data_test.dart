import 'package:astro_log/models/observation_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: subtype_of_sealed_class
class _Document extends Fake implements DocumentReference {}

void main() {
  test(
    'observation preserves Firestore references, dates and numeric values',
    () {
      final equipment = _Document();
      final reference = _Document();
      final time = Timestamp.fromDate(DateTime.utc(2024, 9, 22, 21));
      final observation = ObservationData.fromJson({
        'title': 'M 31',
        'messier': 31,
        'latitude': 40,
        'longitude': -74.5,
        'seeing': 3,
        'equipment': equipment,
        'dateTime': time,
        'notes': ['Clear sky'],
      }, reference: reference);

      expect(observation.reference, same(reference));
      expect(observation.equipmentReference, same(equipment));
      expect(observation.dateTime, time.toDate());
      final data = observation.toJson();
      expect(data['equipment'], same(equipment));
      expect(data['dateTime'], time);
      expect(data['latitude'], isA<int>());
      expect(data['seeing'], isA<int>());
      expect(data['notes'], ['Clear sky']);
      expect(data.containsKey('reference'), isFalse);
    },
  );

  test('observations without equipment remain compatible', () {
    final observation = ObservationData.fromJson({'notes': <String>[]});
    expect(observation.equipmentReference, isNull);
    expect(observation.dateTime, isNull);
    expect(observation.toJson().containsKey('equipment'), isFalse);
  });
}
