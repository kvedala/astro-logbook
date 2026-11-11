import 'package:json_annotation/json_annotation.dart';

import 'ra_dec.dart';

part 'catalog_data.g.dart';

/// The catalog fields shared by the importers and catalog widgets.
@JsonSerializable()
class CatalogData {
  @JsonKey(name: 'number', fromJson: _intFromJson)
  final int id;
  final String catalog;
  final String type;
  @JsonKey(fromJson: RightAscession.fromJSON, toJson: _raToJson)
  final RightAscession ra;
  @JsonKey(fromJson: Declination.fromJSON, toJson: _decToJson)
  final Declination dec;
  final String? difficulty;
  @JsonKey(includeIfNull: false)
  final num? magnitude;
  final bool viewed;
  @JsonKey(includeIfNull: false)
  final String? designation;
  @JsonKey(includeIfNull: false)
  final String? constellation;
  @JsonKey(includeIfNull: false)
  final String? size;
  @JsonKey(includeIfNull: false, fromJson: _nullableIntFromJson)
  final int? distanceLightYears;
  @JsonKey(includeIfNull: false)
  final String? viewingSeason;
  @JsonKey(
    includeIfNull: false,
    fromJson: _numbersFromJson,
    toJson: _numbersToJson,
  )
  final List<int> ngcNumbers;
  @JsonKey(includeIfNull: false)
  final String? info;

  const CatalogData({
    required this.id,
    required this.catalog,
    required this.type,
    required this.ra,
    required this.dec,
    this.difficulty,
    this.magnitude,
    this.viewed = false,
    this.designation,
    this.constellation,
    this.size,
    this.distanceLightYears,
    this.viewingSeason,
    this.ngcNumbers = const [],
    this.info,
  });

  factory CatalogData.fromJson(Map<String, dynamic> json) =>
      _$CatalogDataFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogDataToJson(this);
}

// Keep catalog identifiers strict instead of truncating non-integral numbers.
int _intFromJson(Object? value) => value as int;
int? _nullableIntFromJson(Object? value) => value as int?;
List<int> _numbersFromJson(Object? value) =>
    (value as List<dynamic>? ?? []).cast<int>();
// Legacy catalog exports omit absent links rather than writing an empty list.
List<int>? _numbersToJson(List<int> value) => value.isEmpty ? null : value;
Map<String, dynamic> _raToJson(RightAscession value) => value.json;
Map<String, dynamic> _decToJson(Declination value) => value.json;
