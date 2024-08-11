import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:equatable/equatable.dart';

part 'room.model.freezed.dart';
part 'room.model.g.dart';

@freezed
class RoomModel with _$RoomModel {
  factory RoomModel({
    required String id,
    required String name,
    @Default(0) int deviceCount,
  }) = _RoomModel;

  factory RoomModel.fromJson(Map<String, dynamic> json) => _$RoomModelFromJson(json);
}