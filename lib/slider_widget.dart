import 'package:flutter/material.dart';

/// A slider widget wrapper
class SliderOption extends StatefulWidget {
  /// title of the slider
  final String title;

  /// initial value of the slider
  final num initialValue;

  /// number of divisions
  final int divisions;

  /// minimum slider value
  final num minValue;

  /// maximum slider value
  final num maxValue;

  /// Register callback function when slider value changes
  final void Function(num) onChange;

  /// prefix icon to display
  final IconData? prefixIcon;

  /// A slider widget wrapper
  const SliderOption(this.title, this.onChange,
      {super.key,
      this.initialValue = 0,
      this.minValue = 0,
      this.maxValue = 1.0,
      this.divisions = 1,
      this.prefixIcon});

  @override
  State<SliderOption> createState() => _SliderOptionState();
}

class _SliderOptionState extends State<SliderOption> {
  late num value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    if (value < widget.minValue) {
      value = widget.minValue;
    } else if (value > widget.maxValue) {
      value = widget.maxValue;
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: "${widget.title}: $value",
        prefixIcon: Icon(
          widget.prefixIcon,
          color: Colors.red,
        ),
        prefixIconConstraints: BoxConstraints.loose(const Size(10, 10)),
      ),
      child: Slider(
        value: value as double,
        min: widget.minValue as double,
        max: widget.maxValue as double,
        divisions: widget.divisions,
        onChanged: (newValue) {
          widget.onChange(newValue);
          setState(() => value = newValue);
        },
      ),
    );
  }
}
