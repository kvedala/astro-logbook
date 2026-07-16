// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ObservationData _$ObservationDataFromJson(Map<String, dynamic> json) =>
    ObservationData(
      title: json['title'] as String?,
      ngc: (json['ngc'] as num?)?.toInt(),
      messier: (json['messier'] as num?)?.toInt(),
      fileName: json['fileName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      location: json['location'] as String?,
      seeing: (json['seeing'] as num?)?.toDouble(),
      visibility: (json['visibility'] as num?)?.toDouble(),
      transparency: (json['transparency'] as num?)?.toDouble(),
      dateTime: ObservationData._dateTimeFromJson(json['dateTime']),
      notes:
          (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
    );

Map<String, dynamic> _$ObservationDataToJson(ObservationData instance) =>
    <String, dynamic>{
      'title': instance.title,
      'ngc': instance.ngc,
      'messier': instance.messier,
      'fileName': instance.fileName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'location': instance.location,
      'seeing': instance.seeing,
      'visibility': instance.visibility,
      'transparency': instance.transparency,
      'dateTime': ObservationData._dateTimeToJson(instance.dateTime),
      'notes': instance.notes,
    };
