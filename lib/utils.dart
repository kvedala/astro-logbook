String decimalDegreesToDMS(num numeric, String latOrLong) {
  bool isNegative = false;
  if (numeric < 0) {
    isNegative = true;
    numeric = -numeric;
  }
  int degree = numeric.toDouble().floor();
  int minute = ((numeric - degree) * 60).toDouble().floor();
  double seconds = (((numeric - degree).toDouble() * 60) - minute) * 60;

  return "$degree\xb0 $minute\' ${seconds.toStringAsFixed(1)}\" " +
      (latOrLong == 'lat'
          ? (isNegative ? "S" : "N")
          : (isNegative ? "W" : "E"));
}
