import 'package:astro_log/checklist.dart';
import 'package:astro_log/checklist_item.dart';
import 'package:astro_log/models/checklist_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// The fake batch uses this reference only to identify the document.
// ignore: subtype_of_sealed_class
class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

class _Batch extends Fake implements WriteBatch {
  _Batch(this.reference, this.data);

  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic> data;
  bool committed = false;

  void _write<T>(
    DocumentReference<T> document,
    T value, {
    required bool merge,
  }) {
    if (!identical(document, reference) || value is! Map<String, dynamic>) {
      throw StateError('Unexpected checklist write');
    }
    if (!merge) data.clear();
    data.addAll(value);
  }

  @override
  void update<T>(DocumentReference<T> document, T value) =>
      _write(document, value, merge: true);

  @override
  void set<T>(DocumentReference<T> document, T value, [SetOptions? options]) =>
      _write(document, value, merge: options?.merge == true);

  @override
  Future<void> commit() async {
    committed = true;
  }
}

void main() {
  test('checklist records retain optional catalog metadata', () {
    final catalog = ChecklistData.fromJson({
      'title': 'M 31',
      'value': true,
      'kind': 'catalogObject',
      'catalog': 'Messier',
      'number': 31,
    });
    expect(catalog.toJson(), {
      'title': 'M 31',
      'value': true,
      'kind': 'catalogObject',
      'catalog': 'Messier',
      'number': 31,
    });
    expect(
      ChecklistData(title: 'Eyepiece', value: false).toJson(),
      {'title': 'Eyepiece', 'value': false},
    );
  });

  test('saving a checked catalog object preserves its metadata', () async {
    final reference = _Document();
    final data = <String, dynamic>{
      'title': 'M 31',
      'value': false,
      'kind': 'catalogObject',
      'catalog': 'Messier',
      'number': 31,
    };
    final batch = _Batch(reference, data);
    final item = CheckListItem('M 31', reference: reference);
    item.data['value'] = true;

    await CheckList.saveItems(batch, [item]);

    expect(batch.committed, isTrue);
    expect(data, {
      'title': 'M 31',
      'value': true,
      'kind': 'catalogObject',
      'catalog': 'Messier',
      'number': 31,
    });
  });
}
