import 'package:json_annotation/json_annotation.dart';

part 'checklist_data.g.dart';

/// Custom checklist items may omit the metadata used by catalog items.
@JsonSerializable()
class ChecklistData {
  @JsonKey(required: true)
  final String? title;
  @JsonKey(required: true)
  final bool? value;
  @JsonKey(includeIfNull: false)
  final String? kind;
  @JsonKey(includeIfNull: false)
  final String? catalog;
  @JsonKey(includeIfNull: false)
  final int? number;

  const ChecklistData({
    required this.title,
    required this.value,
    this.kind,
    this.catalog,
    this.number,
  });

  factory ChecklistData.fromJson(Map<String, dynamic> json) =>
      _$ChecklistDataFromJson(json);

  Map<String, dynamic> toJson() => _$ChecklistDataToJson(this);
}
