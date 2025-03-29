import 'package:freezed_annotation/freezed_annotation.dart';

part 'room.model.freezed.dart';
part 'room.model.g.dart';

@freezed
class RoomModel with _$RoomModel {
  factory RoomModel({
    required String id,
    required String name,
  }) = _RoomModel;

  factory RoomModel.fromJson(Map<String, dynamic> json) => _$RoomModelFromJson(json);
}