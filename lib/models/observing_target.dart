import 'package:json_annotation/json_annotation.dart';

import 'ra_dec.dart';

part 'observing_target.g.dart';

@JsonSerializable(constructor: '_json', createToJson: false)
class ObservingTarget {
  @JsonKey(fromJson: _intFromJson)
  final int number;
  final bool isNgc;
  final String type;
  final String? constellation;
  final num? magnitude;
  @JsonKey(fromJson: RightAscession.fromJSON)
  final RightAscession ra;
  @JsonKey(fromJson: Declination.fromJSON)
  final Declination dec;
  @JsonKey(fromJson: _numbersFromJson)
  final List<int> ngcNumbers;
  @JsonKey(fromJson: _numbersFromJson)
  final List<int> messierNumbers;

  const ObservingTarget(
    this.number,
    this.type,
    this.constellation,
    this.magnitude,
    this.ra,
    this.dec, [
    this.ngcNumbers = const [],
  ]) : isNgc = false,
       messierNumbers = const [];

  const ObservingTarget.ngc(
    this.number,
    this.type,
    this.constellation,
    this.magnitude,
    this.ra,
    this.dec, [
    this.messierNumbers = const [],
  ]) : isNgc = true,
       ngcNumbers = const [];

  const ObservingTarget._json({
    required this.number,
    required this.isNgc,
    required this.type,
    this.constellation,
    this.magnitude,
    required this.ra,
    required this.dec,
    this.ngcNumbers = const [],
    this.messierNumbers = const [],
  });

  factory ObservingTarget.fromMessierJson(Map<String, dynamic> json) =>
      _$ObservingTargetFromJson({
        ...json,
        'isNgc': false,
        'messierNumbers': null,
      });

  factory ObservingTarget.fromNgcJson(Map<String, dynamic> json) =>
      _$ObservingTargetFromJson({...json, 'isNgc': true, 'ngcNumbers': null});
}

int _intFromJson(Object? value) => value as int;

List<int> _numbersFromJson(Object? value) =>
    (value as List<dynamic>? ?? []).cast<int>();
