// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outlet.model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OutletModel _$OutletModelFromJson(Map<String, dynamic> json) {
  return _OutletModel.fromJson(json);
}

/// @nodoc
mixin _$OutletModel {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get ip => throw _privateConstructorUsedError;
  String get roomId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OutletModelCopyWith<OutletModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OutletModelCopyWith<$Res> {
  factory $OutletModelCopyWith(
          OutletModel value, $Res Function(OutletModel) then) =
      _$OutletModelCopyWithImpl<$Res, OutletModel>;
  @useResult
  $Res call({String id, String label, String ip, String roomId});
}

/// @nodoc
class _$OutletModelCopyWithImpl<$Res, $Val extends OutletModel>
    implements $OutletModelCopyWith<$Res> {
  _$OutletModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? ip = null,
    Object? roomId = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      ip: null == ip
          ? _value.ip
          : ip // ignore: cast_nullable_to_non_nullable
              as String,
      roomId: null == roomId
          ? _value.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OutletModelImplCopyWith<$Res>
    implements $OutletModelCopyWith<$Res> {
  factory _$$OutletModelImplCopyWith(
          _$OutletModelImpl value, $Res Function(_$OutletModelImpl) then) =
      __$$OutletModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String label, String ip, String roomId});
}

/// @nodoc
class __$$OutletModelImplCopyWithImpl<$Res>
    extends _$OutletModelCopyWithImpl<$Res, _$OutletModelImpl>
    implements _$$OutletModelImplCopyWith<$Res> {
  __$$OutletModelImplCopyWithImpl(
      _$OutletModelImpl _value, $Res Function(_$OutletModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? ip = null,
    Object? roomId = null,
  }) {
    return _then(_$OutletModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      ip: null == ip
          ? _value.ip
          : ip // ignore: cast_nullable_to_non_nullable
              as String,
      roomId: null == roomId
          ? _value.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OutletModelImpl implements _OutletModel {
  _$OutletModelImpl(
      {required this.id,
      required this.label,
      required this.ip,
      required this.roomId});

  factory _$OutletModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OutletModelImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final String ip;
  @override
  final String roomId;

  @override
  String toString() {
    return 'OutletModel(id: $id, label: $label, ip: $ip, roomId: $roomId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OutletModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.ip, ip) || other.ip == ip) &&
            (identical(other.roomId, roomId) || other.roomId == roomId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, label, ip, roomId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OutletModelImplCopyWith<_$OutletModelImpl> get copyWith =>
      __$$OutletModelImplCopyWithImpl<_$OutletModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OutletModelImplToJson(
      this,
    );
  }
}

abstract class _OutletModel implements OutletModel {
  factory _OutletModel(
      {required final String id,
      required final String label,
      required final String ip,
      required final String roomId}) = _$OutletModelImpl;

  factory _OutletModel.fromJson(Map<String, dynamic> json) =
      _$OutletModelImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  String get ip;
  @override
  String get roomId;
  @override
  @JsonKey(ignore: true)
  _$$OutletModelImplCopyWith<_$OutletModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
