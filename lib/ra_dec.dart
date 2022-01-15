import 'dart:math';

/// Define a Right Ascession object
class RightAscession {
  final int hour;
  final num minute;
  final num second;

  const RightAscession(this.hour, this.minute, [this.second = 0]);

  factory RightAscession.fromJSON(Map<String, dynamic> json) =>
      RightAscession(json["hour"] as int, json["minute"] as num);

  double get hours => hour + (minute + (second / 60)) / 60;
  double get degree => hours * 15;
  double get radian => degree * pi / 180.0;

  Map<String, num> get json => {"hour": hour, "minute": minute};

  @override
  String toString() => "$hour h $minute min";
}

/// Define a Declination object
class Declination {
  final int _deg;
  final num _minute;
  final num _second;
  final String _sign;

  const Declination(this._deg, this._minute, this._sign, [this._second = 0]);

  factory Declination.fromJSON(Map<String, dynamic> json) => Declination(
      json["degree"] as int, json["minute"] as num, json["sign"] as String);

  double get degree {
    final val = (_deg) + ((_minute) + (_second / 60)) / 60;
    return _sign == "+" ? val : -val;
  }

  double get radian => degree * pi / 180.0;

  Map<String, dynamic> get json =>
      {"degree": _deg, "minute": _minute, "sign": _sign};

  @override
  String toString() => "$_sign$_deg° $_minute'";
}
