import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SliderOption extends StatefulWidget {
  final String title;
  num value;
  final int divisions;
  final num minValue;
  final num maxValue;
  final void Function(num) onChange;

  SliderOption(this.title, this.onChange,
      {Key key,
      this.value = 0,
      this.minValue = 0,
      this.maxValue = 1.0,
      this.divisions = 1})
      : super(key: key);

  _SliderOptionState createState() => _SliderOptionState();
}

class _SliderOptionState extends State<SliderOption> {
  @override
  Widget build(BuildContext context) {
    if (widget.value < widget.minValue)
      widget.value = widget.minValue;
    else if (widget.value > widget.maxValue) widget.value = widget.maxValue;

    return Container(
      child: Row(
        children: [
          Text(widget.title + ": ${widget.value}"),
          Slider(
            value: widget.value,
            min: widget.minValue,
            max: widget.maxValue,
            divisions: widget.divisions,
            onChanged: (value) {
              widget.onChange(value);
              setState(() => widget.value = value);
            },
          ),
        ],
      ),
    );
  }
}
