import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SliderOption extends StatefulWidget {
  final String title;
  final num initialValue;
  final int divisions;
  final num minValue;
  final num maxValue;
  final void Function(num) onChange;
  final IconData prefixIcon;

  SliderOption(this.title, this.onChange,
      {Key key,
      this.initialValue = 0,
      this.minValue = 0,
      this.maxValue = 1.0,
      this.divisions = 1,
      this.prefixIcon})
      : super(key: key);

  _SliderOptionState createState() => _SliderOptionState();
}

class _SliderOptionState extends State<SliderOption> {
  num value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    if (value < widget.minValue)
      value = widget.minValue;
    else if (value > widget.maxValue) value = widget.maxValue;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.title + ": $value",
        prefixIcon: Icon(
          widget.prefixIcon,
          color: Colors.red,
        ),
        prefixIconConstraints: BoxConstraints.loose(Size(10, 10)),
      ),
      child: Slider(
        value: value,
        min: widget.minValue,
        max: widget.maxValue,
        divisions: widget.divisions,
        onChanged: (newValue) {
          widget.onChange(newValue);
          setState(() => value = newValue);
        },
      ),
    );
  }
}
