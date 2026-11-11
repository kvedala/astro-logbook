import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'observation_data.g.dart';

/// An observation's persisted fields, plus its separately attached document reference.
@JsonSerializable()
class ObservationData {
  final String? title;
  final int? ngc;
  final int? messier;
  final String? fileName;
  final num? latitude;
  final num? longitude;
  final String? location;
  final num? seeing;
  final num? visibility;
  final num? transparency;
  // Equipment is stored as a Firestore reference, not an embedded object.
  @JsonKey(
    name: 'equipment',
    fromJson: _referenceFromJson,
    toJson: _referenceToJson,
    includeIfNull: false,
  )
  final DocumentReference? equipmentReference;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? dateTime;
  final List<String> notes;

  // The Firestore document reference is attached separately and is not serialized.
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
    this.equipmentReference,
    this.dateTime,
    this.notes = const [],
    this.reference,
  });

  /// Decode Firestore fields and attach the document reference separately.
  factory ObservationData.fromJson(
    Map<String, dynamic> json, {
    DocumentReference? reference,
  }) => _$ObservationDataFromJson(json).copyWith(reference: reference);

  Map<String, dynamic> toJson() => _$ObservationDataToJson(this);

  // Firestore stores this field as a Timestamp, not a JSON date string.
  static DateTime? _dateTimeFromJson(dynamic timestamp) =>
      timestamp != null ? (timestamp as Timestamp).toDate() : null;

  static dynamic _dateTimeToJson(DateTime? dateTime) =>
      dateTime != null ? Timestamp.fromDate(dateTime) : null;

  static DocumentReference? _referenceFromJson(Object? value) =>
      value as DocumentReference?;

  static Object? _referenceToJson(DocumentReference? value) => value;

  /// Copy the observation, preserving its reference when none is supplied.
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
      equipmentReference: equipmentReference,
      dateTime: dateTime,
      notes: notes,
      reference: reference ?? this.reference,
    );
  }
}
