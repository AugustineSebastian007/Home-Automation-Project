// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outlet.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OutletModelImpl _$$OutletModelImplFromJson(Map<String, dynamic> json) =>
    _$OutletModelImpl(
      id: json['id'] as String,
      label: json['label'] as String,
      ip: json['ip'] as String,
      roomId: json['roomId'] as String,
    );

Map<String, dynamic> _$$OutletModelImplToJson(_$OutletModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'ip': instance.ip,
      'roomId': instance.roomId,
    };
