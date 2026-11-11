import 'package:json_annotation/json_annotation.dart';

part 'equipment_data.g.dart';

@JsonSerializable()
class EquipmentData {
  final String? telescope;
  final num? aperture;
  final num? focalLength;
  final String? mount;

  const EquipmentData({
    this.telescope,
    this.aperture,
    this.focalLength,
    this.mount,
  });

  factory EquipmentData.fromJson(Map<String, dynamic> json) =>
      _$EquipmentDataFromJson(json);

  Map<String, dynamic> toJson() => _$EquipmentDataToJson(this);
}
