import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Checklist item widget
class CheckListItem extends StatefulWidget {
  /// Checklist item description
  final String? title;

  /// initial value of the checklist item
  final bool? _initialValue;

  /// callback function when check state changed
  final void Function(bool?)? onChanged;

  /// DB reference of the check item
  final DocumentReference? reference;

  /// checkitem as JSON
  final Map<String, dynamic> data = {};

  /// Checklist item widget
  CheckListItem(this.title,
      {this.reference, this.onChanged, bool? initialValue = false, Key? key})
      : _initialValue = initialValue,
        super(key: key) {
    data['title'] = title;
    data['value'] = initialValue;
  }

  _CheckListItemState createState() => _CheckListItemState();

  /// check if the state changed
  bool get hasChanged => data['value'] != _initialValue;
}

class _CheckListItemState extends State<CheckListItem> {
  void _updateItem() async {
    await widget.reference!.update({'value': widget.data['value']});
  }

  @override
  void dispose() {
    if (widget.hasChanged) _updateItem();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.title!),
      value: widget.data['value'],
      checkColor: Colors.red,
      activeColor: Colors.grey.shade800,
      onChanged: (val) async {
        setState(() => widget.data['value'] = val);
        // await widget.reference.update({'value': val});
        if (widget.onChanged != null) widget.onChanged!(val);
      },
    );
  }
}
