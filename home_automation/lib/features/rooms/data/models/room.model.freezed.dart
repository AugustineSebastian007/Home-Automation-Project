// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room.model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RoomModel _$RoomModelFromJson(Map<String, dynamic> json) {
  return _RoomModel.fromJson(json);
}

/// @nodoc
mixin _$RoomModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get deviceCount => throw _privateConstructorUsedError;
  OutletModel? get defaultOutlet => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoomModelCopyWith<RoomModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomModelCopyWith<$Res> {
  factory $RoomModelCopyWith(RoomModel value, $Res Function(RoomModel) then) =
      _$RoomModelCopyWithImpl<$Res, RoomModel>;
  @useResult
  $Res call(
      {String id, String name, int deviceCount, OutletModel? defaultOutlet});

  $OutletModelCopyWith<$Res>? get defaultOutlet;
}

/// @nodoc
class _$RoomModelCopyWithImpl<$Res, $Val extends RoomModel>
    implements $RoomModelCopyWith<$Res> {
  _$RoomModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? deviceCount = null,
    Object? defaultOutlet = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      deviceCount: null == deviceCount
          ? _value.deviceCount
          : deviceCount // ignore: cast_nullable_to_non_nullable
              as int,
      defaultOutlet: freezed == defaultOutlet
          ? _value.defaultOutlet
          : defaultOutlet // ignore: cast_nullable_to_non_nullable
              as OutletModel?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $OutletModelCopyWith<$Res>? get defaultOutlet {
    if (_value.defaultOutlet == null) {
      return null;
    }

    return $OutletModelCopyWith<$Res>(_value.defaultOutlet!, (value) {
      return _then(_value.copyWith(defaultOutlet: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RoomModelImplCopyWith<$Res>
    implements $RoomModelCopyWith<$Res> {
  factory _$$RoomModelImplCopyWith(
          _$RoomModelImpl value, $Res Function(_$RoomModelImpl) then) =
      __$$RoomModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String name, int deviceCount, OutletModel? defaultOutlet});

  @override
  $OutletModelCopyWith<$Res>? get defaultOutlet;
}

/// @nodoc
class __$$RoomModelImplCopyWithImpl<$Res>
    extends _$RoomModelCopyWithImpl<$Res, _$RoomModelImpl>
    implements _$$RoomModelImplCopyWith<$Res> {
  __$$RoomModelImplCopyWithImpl(
      _$RoomModelImpl _value, $Res Function(_$RoomModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? deviceCount = null,
    Object? defaultOutlet = freezed,
  }) {
    return _then(_$RoomModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      deviceCount: null == deviceCount
          ? _value.deviceCount
          : deviceCount // ignore: cast_nullable_to_non_nullable
              as int,
      defaultOutlet: freezed == defaultOutlet
          ? _value.defaultOutlet
          : defaultOutlet // ignore: cast_nullable_to_non_nullable
              as OutletModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomModelImpl implements _RoomModel {
  _$RoomModelImpl(
      {required this.id,
      required this.name,
      this.deviceCount = 0,
      this.defaultOutlet});

  factory _$RoomModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final int deviceCount;
  @override
  final OutletModel? defaultOutlet;

  @override
  String toString() {
    return 'RoomModel(id: $id, name: $name, deviceCount: $deviceCount, defaultOutlet: $defaultOutlet)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.deviceCount, deviceCount) ||
                other.deviceCount == deviceCount) &&
            (identical(other.defaultOutlet, defaultOutlet) ||
                other.defaultOutlet == defaultOutlet));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, deviceCount, defaultOutlet);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomModelImplCopyWith<_$RoomModelImpl> get copyWith =>
      __$$RoomModelImplCopyWithImpl<_$RoomModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomModelImplToJson(
      this,
    );
  }
}

abstract class _RoomModel implements RoomModel {
  factory _RoomModel(
      {required final String id,
      required final String name,
      final int deviceCount,
      final OutletModel? defaultOutlet}) = _$RoomModelImpl;

  factory _RoomModel.fromJson(Map<String, dynamic> json) =
      _$RoomModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get deviceCount;
  @override
  OutletModel? get defaultOutlet;
  @override
  @JsonKey(ignore: true)
  _$$RoomModelImplCopyWith<_$RoomModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
