import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SliderOption extends StatefulWidget {
  final String title;
  num value;
  final int divisions;
  final num minValue;
  final num maxValue;
  final void Function(num) onChange;
  final IconData prefixIcon;

  SliderOption(this.title, this.onChange,
      {Key key,
      this.value = 0,
      this.minValue = 0,
      this.maxValue = 1.0,
      this.divisions = 1,
      this.prefixIcon})
      : super(key: key);

  _SliderOptionState createState() => _SliderOptionState();
}

class _SliderOptionState extends State<SliderOption> {
  @override
  Widget build(BuildContext context) {
    if (widget.value < widget.minValue)
      widget.value = widget.minValue;
    else if (widget.value > widget.maxValue) widget.value = widget.maxValue;

    return InputDecorator(
      decoration: InputDecoration(
          labelText: widget.title + ": ${widget.value}",
          prefixIcon: Icon(
            widget.prefixIcon,
            color: Colors.red,
          )),
      child: Slider(
        value: widget.value,
        min: widget.minValue,
        max: widget.maxValue,
        divisions: widget.divisions,
        onChanged: (value) {
          widget.onChange(value);
          setState(() => widget.value = value);
        },
      ),
    );
  }
}
