import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CheckListItem extends StatefulWidget {
  final String title;
  final bool _initialValue;
  final void Function(bool) onChanged;
  final DocumentReference reference;
  final Map<String, dynamic> data = {};

  CheckListItem(this.title,
      {this.reference, this.onChanged, bool initialValue = false, Key key})
      : _initialValue = initialValue,
        super(key: key) {
    data['title'] = title;
    data['value'] = initialValue;
  }

  _CheckListItemState createState() => _CheckListItemState();

  bool get hasChanged => data['value'] != _initialValue;
}

class _CheckListItemState extends State<CheckListItem> {
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.title),
      value: widget.data['value'],
      checkColor: Colors.red,
      activeColor: Colors.grey.shade800,
      onChanged: (val) {
        setState(() => widget.data['value'] = val);
        if (widget.onChanged != null) widget.onChanged(val);
      },
    );
  }
}
