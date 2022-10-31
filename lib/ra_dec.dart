import 'dart:math';

/// Define a Right Ascession object
class RightAscession {
  final int hour;
  final num minute;
  final num second;

  /// Create a constant instance
  const RightAscession(this.hour, this.minute, [this.second = 0]);

  /// Generate the vinstance from a JSON map object
  factory RightAscession.fromJSON(Map<String, dynamic> json) => RightAscession(
        json["hour"] as int,
        json["minute"] as num,
        (json["second"] ?? 0) as num,
      );

  /// get the value in decimal hours
  double get hours => hour + (minute + (second / 60)) / 60;

  /// get the value in decimal degrees
  double get degree => hours * 15;

  /// get the value in decimal radian
  double get radian => degree * pi / 180.0;

  /// get the object as a JSON object
  Map<String, num> get json => {
        "hour": hour,
        "minute": minute,
        "second": second,
      };

  @override
  String toString() => "$hour h $minute min";
}

/// Define a Declination object
class Declination {
  final int _deg;
  final num _minute;
  final num _second;
  final String _sign;

  /// Create a constant instance
  const Declination(this._deg, this._minute, this._sign, [this._second = 0]);

  /// Generate the vinstance from a JSON map object
  factory Declination.fromJSON(Map<String, dynamic> json) => Declination(
        json["degree"] as int,
        json["minute"] as num,
        json["sign"] as String,
        (json["second"] ?? 0) as num,
      );

  /// get the value in decimal degree
  double get degree {
    final val = (_deg) + ((_minute) + (_second / 60)) / 60;
    return _sign == "+" ? val : -val;
  }

  /// get the value in decimal radian
  double get radian => degree * pi / 180.0;

  /// get the object as a JSON object
  Map<String, dynamic> get json => {
        "degree": _deg,
        "minute": _minute,
        "second": _second,
        "sign": _sign,
      };

  @override
  String toString() => "$_sign$_deg° $_minute'";
}
