import 'package:freezed_annotation/freezed_annotation.dart';

part 'outlet.model.freezed.dart';
part 'outlet.model.g.dart';

@freezed
class OutletModel with _$OutletModel {
  factory OutletModel({
    required String id,
    required String label,
    required String ip,
    required String roomId,
  }) = _OutletModel;

  factory OutletModel.fromJson(Map<String, dynamic> json) => _$OutletModelFromJson(json);
}
