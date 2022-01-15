import 'dart:math';

/// Define a Right Ascession object
class RightAscession {
  final int _hour;
  final num _minute;

  RightAscession(this._hour, this._minute);
  factory RightAscession.fromJSON(Map<String, dynamic> json) =>
      RightAscession(json["hour"] as int, json["minute"] as num);

  double get degree => (_hour * 15) + (_minute * 15) / 60;
  double get radian => degree * pi / 180.0;

  Map<String, num> get json => {"hour": _hour, "minute": _minute};
}

/// Define a Declination object
class Declination {
  final int _deg;
  final num _minute;
  final String _sign;

  Declination(this._deg, this._minute, this._sign);
  factory Declination.fromJSON(Map<String, dynamic> json) => Declination(
      json["degree"] as int, json["minute"] as num, json["sign"] as String);

  double get degree => (_deg) + (_minute) / 60;
  double get radian => degree * pi / 180.0;

  Map<String, dynamic> get json =>
      {"degree": _deg, "minute": _minute, "sign": _sign};
}
