import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'objects.dart';
import 'ra_dec.dart';

/// Parse the Messier CSV into normalized records.
List<Messier> parseMessierCsv(String data) {
  final out1 = csv.decode(data);
  out1.removeAt(0);
  return out1
      .map<Messier>((item) {
        final ra = item[4] as String;
        String dec = item[5] as String;
        String sign = '+';
        if (dec[0] == '-') {
          sign = '-';
          dec = dec.substring(1);
        }

        // The CSV stores coordinates as formatted sexagesimal strings.
        int splitIndexRA = ra.indexOf("h ");
        int splitIndexDEC = dec.indexOf("°");

        return Messier(
          int.parse((item[0] as String).substring(1)),
          item[2] as String,
          RightAscession(
            int.parse(ra.substring(0, splitIndexRA)),
            double.parse(ra.substring(splitIndexRA + 2, ra.length - 1)),
          ),
          Declination(
            int.parse(dec.substring(0, splitIndexDEC)),
            double.parse(dec.substring(splitIndexDEC + 1)),
            sign,
          ),
          difficulty: item[10],
          magnitude: num.parse(item[6].toString()),
          designation: item[1] as String,
          constellation: item[3] as String,
          size: item[7].toString(),
          distanceLightYears: int.parse(item[8].toString().replaceAll(',', '')),
          viewingSeason: item[9] as String,
        );
      })
      .toList(growable: false);
}

/// Add missing catalog fields without replacing existing Firestore values.
Future<QuerySnapshot<Map<String, dynamic>>> uploadMessier() async {
  final data = await rootBundle.loadString("assets/messier.csv");
  final objects = parseMessierCsv(data);
  final collection = FirebaseFirestore.instance.collection('messier');
  final existing = await collection.get(
    const GetOptions(source: Source.server),
  );
  final references = <int, DocumentReference<Map<String, dynamic>>>{};
  for (final doc in existing.docs) {
    final number = doc.data()['number'];
    if (number is int) {
      if (references.containsKey(number)) {
        throw StateError('Duplicate Messier number in Firestore: $number');
      }
      references[number] = doc.reference;
    }
  }
  final numbers = <int>{};
  for (final element in objects) {
    if (!numbers.add(element.id)) {
      throw StateError('Duplicate Messier number in CSV: ${element.id}');
    }
    if (!references.containsKey(element.id)) {
      throw StateError('Missing Messier number in Firestore: ${element.id}');
    }
  }
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshots = <int, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final element in objects) {
      final snapshot = await transaction.get(references[element.id]!);
      if (!snapshot.exists || snapshot.data()?['number'] != element.id) {
        throw StateError('Messier ${element.id} changed during the import');
      }
      snapshots[element.id] = snapshot;
    }
    for (final element in objects) {
      final existingFields = snapshots[element.id]!.data()!;
      final fields = element.json
        ..remove('viewed')
        ..remove('catalog');
      fields.removeWhere((key, _) => existingFields.containsKey(key));
      if (fields.isNotEmpty) {
        transaction.update(references[element.id]!, fields);
      }
    }
  });
  return collection
      .orderBy("number")
      .get(const GetOptions(source: Source.server));
}

/// Parse the NGC CSV into normalized records.
List<NGC> parseNGCCsv(String data) {
  final rows = csv.decode(data)..removeAt(0);
  String? optional(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
  }

  return rows
      .map<NGC>((item) {
        final magnitude = optional(item[4]);
        return NGC(
          int.parse(item[0].toString().trim()),
          item[2] as String,
          RightAscession(
            int.parse(item[6].toString().trim()),
            num.parse(item[7].toString().trim()),
          ),
          Declination(
            int.parse(item[9].toString().trim()),
            num.parse(item[10].toString().trim()),
            item[8] as String,
          ),
          magnitude: magnitude == null ? null : num.parse(magnitude),
          designation: optional(item[1]),
          constellation: optional(item[3]),
          info: optional(item[5]),
        );
      })
      .toList(growable: false);
}

String constellationName(String constellation) {
  const names = {
    'And': 'Andromeda',
    'Ant': 'Antlia',
    'Aps': 'Apus',
    'Aql': 'Aquila',
    'Aqr': 'Aquarius',
    'Ara': 'Ara',
    'Ari': 'Aries',
    'Aur': 'Auriga',
    'Boo': 'Boötes',
    'CMa': 'Canis Major',
    'CMi': 'Canis Minor',
    'CVn': 'Canes Venatici',
    'Cae': 'Caelum',
    'Cam': 'Camelopardalis',
    'Cap': 'Capricornus',
    'Car': 'Carina',
    'Cas': 'Cassiopeia',
    'Cen': 'Centaurus',
    'Cep': 'Cepheus',
    'Cet': 'Cetus',
    'Cha': 'Chamaeleon',
    'Cir': 'Circinus',
    'Cnc': 'Cancer',
    'Col': 'Columba',
    'Com': 'Coma Berenices',
    'CrA': 'Corona Australis',
    'CrB': 'Corona Borealis',
    'Crt': 'Crater',
    'Cru': 'Crux',
    'Crv': 'Corvus',
    'Cyg': 'Cygnus',
    'Del': 'Delphinus',
    'Dor': 'Dorado',
    'Dra': 'Draco',
    'Equ': 'Equuleus',
    'Eri': 'Eridanus',
    'For': 'Fornax',
    'Gem': 'Gemini',
    'Gru': 'Grus',
    'Her': 'Hercules',
    'Hor': 'Horologium',
    'Hya': 'Hydra',
    'Hyi': 'Hydrus',
    'Ind': 'Indus',
    'LMi': 'Leo Minor',
    'Lac': 'Lacerta',
    'Leo': 'Leo',
    'Lep': 'Lepus',
    'Lib': 'Libra',
    'Lup': 'Lupus',
    'Lyn': 'Lynx',
    'Lyr': 'Lyra',
    'Men': 'Mensa',
    'Mic': 'Microscopium',
    'Mon': 'Monoceros',
    'Mus': 'Musca',
    'Nor': 'Norma',
    'Oct': 'Octans',
    'Oph': 'Ophiuchus',
    'Ori': 'Orion',
    'Pav': 'Pavo',
    'Peg': 'Pegasus',
    'Per': 'Perseus',
    'Phe': 'Phoenix',
    'Pic': 'Pictor',
    'PsA': 'Piscis Austrinus',
    'Psc': 'Pisces',
    'Pup': 'Puppis',
    'Pyx': 'Pyxis',
    'Ret': 'Reticulum',
    'Scl': 'Sculptor',
    'Sco': 'Scorpius',
    'Sct': 'Scutum',
    'Ser': 'Serpens',
    'Sex': 'Sextans',
    'Sge': 'Sagitta',
    'Sgr': 'Sagittarius',
    'Tau': 'Taurus',
    'Tel': 'Telescopium',
    'TrA': 'Triangulum Australe',
    'Tri': 'Triangulum',
    'Tuc': 'Tucana',
    'UMa': 'Ursa Major',
    'UMi': 'Ursa Minor',
    'Vel': 'Vela',
    'Vir': 'Virgo',
    'Vol': 'Volans',
    'Vul': 'Vulpecula',
  };
  final value = constellation.trim();
  return names[value] ?? value;
}

Map<String, dynamic> ngcConstellationUpdates(
  NGC object,
  Map<String, dynamic> existing,
) {
  final constellation = existing['constellation'];
  if (constellation is String &&
      object.constellation != null &&
      constellation != object.constellation &&
      constellationName(constellation) == object.constellation) {
    return {'constellation': object.constellation};
  }
  return {};
}

/// Prepare missing fields and correct known legacy constellation abbreviations.
Map<String, dynamic> ngcUpdates(NGC object, Map<String, dynamic> existing) {
  final fields = object.json
    ..remove('viewed')
    ..remove('catalog');
  fields.removeWhere(
    (key, value) => value == null || existing.containsKey(key),
  );
  fields.addAll(ngcConstellationUpdates(object, existing));
  final difficulty = existing['difficulty'];
  if (difficulty is String && difficulty.trim().toLowerCase() == 'null') {
    fields['difficulty'] = FieldValue.delete();
  }
  return fields;
}

/// Add missing catalog fields and expand matching constellation abbreviations.
///
/// Each transaction commits up to 100 documents. If interrupted, rerunning
/// the importer safely continues with fields that are still missing.
/// Set [constellationsOnly] to update only matching legacy abbreviations.
Future<QuerySnapshot<Map<String, dynamic>>> uploadNGC({
  void Function(int completed, int total)? onProgress,
  bool constellationsOnly = false,
}) async {
  final objects = parseNGCCsv(
    await rootBundle.loadString("assets/NGCObjects.csv"),
  );
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('ngc');
  final existing = await collection.get(
    const GetOptions(source: Source.server),
  );
  final references = <int, DocumentReference<Map<String, dynamic>>>{};
  for (final doc in existing.docs) {
    final number = doc.data()['number'];
    if (number is int) {
      if (references.containsKey(number)) {
        throw StateError('Duplicate NGC number in Firestore: $number');
      }
      references[number] = doc.reference;
    }
  }

  final numbers = <int>{};
  for (final element in objects) {
    if (!numbers.add(element.id)) {
      throw StateError('Duplicate NGC number in CSV: ${element.id}');
    }
    if (!references.containsKey(element.id)) {
      throw StateError('Missing NGC number in Firestore: ${element.id}');
    }
  }

  const chunkSize = 100;
  for (var start = 0; start < objects.length; start += chunkSize) {
    final end = (start + chunkSize).clamp(0, objects.length);
    final chunk = objects.sublist(start, end);
    await firestore.runTransaction((transaction) async {
      final snapshots = <int, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final element in chunk) {
        final snapshot = await transaction.get(references[element.id]!);
        if (!snapshot.exists || snapshot.data()?['number'] != element.id) {
          throw StateError('NGC ${element.id} changed during the import');
        }
        snapshots[element.id] = snapshot;
      }
      for (final element in chunk) {
        final existingFields = snapshots[element.id]!.data()!;
        final fields = constellationsOnly
            ? ngcConstellationUpdates(element, existingFields)
            : ngcUpdates(element, existingFields);
        if (fields.isNotEmpty) {
          transaction.update(references[element.id]!, fields);
        }
      }
    });
    onProgress?.call(end, objects.length);
  }
  return collection
      .orderBy("number")
      .get(const GetOptions(source: Source.server));
}

/// Cross-references explicitly named associations in both bundled catalogs.
Map<int, Set<int>> buildCatalogLinks(List<Messier> messier, List<NGC> ngc) {
  final messierIds = messier.map((object) => object.id).toSet();
  final ngcIds = ngc.map((object) => object.id).toSet();
  final links = <int, Set<int>>{};

  void add(int messierNumber, int ngcNumber) {
    if (!messierIds.contains(messierNumber) || !ngcIds.contains(ngcNumber)) {
      throw StateError('Invalid catalog link M$messierNumber / NGC $ngcNumber');
    }
    links.putIfAbsent(messierNumber, () => <int>{}).add(ngcNumber);
  }

  for (final object in messier) {
    final match = RegExp(
      r'^NGC\s+(\d+)\b',
      caseSensitive: false,
    ).firstMatch(object.designation ?? '');
    if (match != null) add(object.id, int.parse(match[1]!));
  }
  for (final object in ngc) {
    final match = RegExp(
      r'^M\s*(\d+)$',
      caseSensitive: false,
    ).firstMatch(object.designation ?? '');
    if (match != null) add(int.parse(match[1]!), object.id);
  }
  return links;
}

/// Write both directions of the catalog associations in one transaction.
Future<void> syncCatalogLinks() async {
  final messier = parseMessierCsv(
    await rootBundle.loadString('assets/messier.csv'),
  );
  final ngc = parseNGCCsv(await rootBundle.loadString('assets/NGCObjects.csv'));
  final links = buildCatalogLinks(messier, ngc);
  final firestore = FirebaseFirestore.instance;
  final messierDocs = await firestore
      .collection('messier')
      .get(const GetOptions(source: Source.server));
  final ngcDocs = await firestore
      .collection('ngc')
      .get(const GetOptions(source: Source.server));

  Map<int, DocumentReference<Map<String, dynamic>>> references(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final result = <int, DocumentReference<Map<String, dynamic>>>{};
    for (final doc in snapshot.docs) {
      final number = doc.data()['number'];
      if (number is int) {
        if (result.containsKey(number)) {
          throw StateError('Duplicate catalog number: $number');
        }
        result[number] = doc.reference;
      }
    }
    return result;
  }

  final messierRefs = references(messierDocs);
  final ngcRefs = references(ngcDocs);
  final reverse = <int, List<int>>{};
  for (final entry in links.entries) {
    for (final number in entry.value) {
      (reverse[number] ??= []).add(entry.key);
    }
  }
  final updates =
      <
        DocumentReference<Map<String, dynamic>>,
        ({String field, List<int> values, int number})
      >{};
  for (final entry in links.entries) {
    final ref = messierRefs[entry.key];
    if (ref == null) throw StateError('Missing Messier ${entry.key}');
    updates[ref] = (
      field: 'ngcNumbers',
      values: entry.value.toList()..sort(),
      number: entry.key,
    );
  }
  for (final entry in reverse.entries) {
    final ref = ngcRefs[entry.key];
    if (ref == null) throw StateError('Missing NGC ${entry.key}');
    updates[ref] = (
      field: 'messierNumbers',
      values: entry.value..sort(),
      number: entry.key,
    );
  }

  await firestore.runTransaction((transaction) async {
    final missing =
        <
          DocumentReference<Map<String, dynamic>>,
          ({String field, List<int> values, int number})
        >{};
    for (final entry in updates.entries) {
      final snapshot = await transaction.get(entry.key);
      if (!snapshot.exists) {
        throw StateError(
          'Catalog document no longer exists: ${entry.key.path}',
        );
      }
      final data = snapshot.data()!;
      if (data['number'] != entry.value.number) {
        throw StateError('Catalog number changed at ${entry.key.path}');
      }
      final current = data[entry.value.field];
      if (!data.containsKey(entry.value.field)) {
        missing[entry.key] = entry.value;
      } else if (current is! List || !listEquals(current, entry.value.values)) {
        throw StateError('Existing catalog links differ at ${entry.key.path}');
      }
    }
    for (final entry in missing.entries) {
      transaction.update(entry.key, {entry.value.field: entry.value.values});
    }
  });
}
