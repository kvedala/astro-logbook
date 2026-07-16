import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'observation_data.g.dart';

@JsonSerializable()
class ObservationData {
  final String? title;
  final int? ngc;
  final int? messier;
  final String? fileName;
  final double? latitude;
  final double? longitude;
  final String? location;
  final double? seeing;
  final double? visibility;
  final double? transparency;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? dateTime;
  final List<String> notes;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final DocumentReference? reference;

  const ObservationData({
    this.title,
    this.ngc,
    this.messier,
    this.fileName,
    this.latitude,
    this.longitude,
    this.location,
    this.seeing,
    this.visibility,
    this.transparency,
    this.dateTime,
    this.notes = const [],
    this.reference,
  });

  factory ObservationData.fromJson(
    Map<String, dynamic> json, {
    DocumentReference? reference,
  }) => _$ObservationDataFromJson(json).copyWith(reference: reference);

  Map<String, dynamic> toJson() => _$ObservationDataToJson(this);

  static DateTime? _dateTimeFromJson(dynamic timestamp) =>
      timestamp != null ? (timestamp as Timestamp).toDate() : null;

  static dynamic _dateTimeToJson(DateTime? dateTime) =>
      dateTime != null ? Timestamp.fromDate(dateTime) : null;

  ObservationData copyWith({DocumentReference? reference}) {
    return ObservationData(
      title: title,
      ngc: ngc,
      messier: messier,
      fileName: fileName,
      latitude: latitude,
      longitude: longitude,
      location: location,
      seeing: seeing,
      visibility: visibility,
      transparency: transparency,
      dateTime: dateTime,
      notes: notes,
      reference: reference ?? this.reference,
    );
  }
}
