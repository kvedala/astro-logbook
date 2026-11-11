import 'package:astro_log/models/equipment_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('equipment records retain their Firestore fields and numeric types', () {
    final json = <String, dynamic>{
      'telescope': 'Refractor',
      'aperture': 100,
      'focalLength': 750.5,
      'mount': 'Alt-azimuth',
    };
    final data = EquipmentData.fromJson(json);
    expect(data.toJson(), json);
    expect(data.aperture, isA<int>());
    expect(data.focalLength, isA<double>());
  });
}
