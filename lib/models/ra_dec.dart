import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

part 'ra_dec.g.dart';

/// Define a Right Ascession object
@JsonSerializable(constructor: '_json')
class RightAscession {
  @JsonKey(fromJson: _intFromJson)
  final int hour;
  final num minute;
  final num second;

  /// Create a constant instance
  const RightAscession(this.hour, this.minute, [this.second = 0]);

  const RightAscession._json({
    required this.hour,
    required this.minute,
    this.second = 0,
  });

  /// Generate the vinstance from a JSON map object
  factory RightAscession.fromJSON(Map<String, dynamic> json) =>
      _$RightAscessionFromJson(json);

  /// get the value in decimal hours
  double get hours => hour + (minute + (second / 60)) / 60;

  /// get the value in decimal degrees
  // Right ascension is measured in hours, with 15 degrees per hour.
  double get degree => hours * 15;

  /// get the value in decimal radian
  double get radian => degree * pi / 180.0;

  /// get the object as a JSON object
  Map<String, dynamic> get json => _$RightAscessionToJson(this);

  @override
  String toString() => "$hour h $minute min";
}

/// Define a Declination object
@JsonSerializable(constructor: '_json')
class Declination {
  final int _deg;
  final num _minute;
  final num _second;
  final String _sign;

  /// Create a constant instance
  const Declination(this._deg, this._minute, this._sign, [this._second = 0]);

  const Declination._json({
    required int degreesComponent,
    required num minutesComponent,
    required String sign,
    num secondsComponent = 0,
  }) : this(degreesComponent, minutesComponent, sign, secondsComponent);

  @JsonKey(name: 'degree', fromJson: _intFromJson)
  int get degreesComponent => _deg;
  @JsonKey(name: 'minute')
  num get minutesComponent => _minute;
  @JsonKey(name: 'second')
  num get secondsComponent => _second;
  String get sign => _sign;

  /// Generate the vinstance from a JSON map object
  factory Declination.fromJSON(Map<String, dynamic> json) =>
      _$DeclinationFromJson(json);

  /// get the value in decimal degree
  double get degree {
    // Apply the sign to the complete degree-minute-second magnitude.
    final val = (_deg) + ((_minute) + (_second / 60)) / 60;
    return _sign == "+" ? val : -val;
  }

  /// get the value in decimal radian
  double get radian => degree * pi / 180.0;

  /// get the object as a JSON object
  Map<String, dynamic> get json => _$DeclinationToJson(this);

  @override
  String toString() => "$_sign$_deg° $_minute'";
}

int _intFromJson(Object? value) => value as int;
