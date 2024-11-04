// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomModelImpl _$$RoomModelImplFromJson(Map<String, dynamic> json) =>
    _$RoomModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      deviceCount: (json['deviceCount'] as num?)?.toInt() ?? 0,
      defaultOutlet: json['defaultOutlet'] == null
          ? null
          : OutletModel.fromJson(json['defaultOutlet'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$RoomModelImplToJson(_$RoomModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'deviceCount': instance.deviceCount,
      'defaultOutlet': instance.defaultOutlet,
    };
