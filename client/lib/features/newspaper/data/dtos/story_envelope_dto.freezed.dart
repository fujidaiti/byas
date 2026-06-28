// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_envelope_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StoryEnvelopeDto {

 String get type; FeedEntry get data;
/// Create a copy of StoryEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryEnvelopeDtoCopyWith<StoryEnvelopeDto> get copyWith => _$StoryEnvelopeDtoCopyWithImpl<StoryEnvelopeDto>(this as StoryEnvelopeDto, _$identity);

  /// Serializes this StoryEnvelopeDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryEnvelopeDto&&(identical(other.type, type) || other.type == type)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,data);

@override
String toString() {
  return 'StoryEnvelopeDto(type: $type, data: $data)';
}


}

/// @nodoc
abstract mixin class $StoryEnvelopeDtoCopyWith<$Res>  {
  factory $StoryEnvelopeDtoCopyWith(StoryEnvelopeDto value, $Res Function(StoryEnvelopeDto) _then) = _$StoryEnvelopeDtoCopyWithImpl;
@useResult
$Res call({
 String type, FeedEntry data
});


$FeedEntryCopyWith<$Res> get data;

}
/// @nodoc
class _$StoryEnvelopeDtoCopyWithImpl<$Res>
    implements $StoryEnvelopeDtoCopyWith<$Res> {
  _$StoryEnvelopeDtoCopyWithImpl(this._self, this._then);

  final StoryEnvelopeDto _self;
  final $Res Function(StoryEnvelopeDto) _then;

/// Create a copy of StoryEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? data = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as FeedEntry,
  ));
}
/// Create a copy of StoryEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FeedEntryCopyWith<$Res> get data {
  
  return $FeedEntryCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [StoryEnvelopeDto].
extension StoryEnvelopeDtoPatterns on StoryEnvelopeDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryEnvelopeDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryEnvelopeDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryEnvelopeDto value)  $default,){
final _that = this;
switch (_that) {
case _StoryEnvelopeDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryEnvelopeDto value)?  $default,){
final _that = this;
switch (_that) {
case _StoryEnvelopeDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  FeedEntry data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryEnvelopeDto() when $default != null:
return $default(_that.type,_that.data);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  FeedEntry data)  $default,) {final _that = this;
switch (_that) {
case _StoryEnvelopeDto():
return $default(_that.type,_that.data);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  FeedEntry data)?  $default,) {final _that = this;
switch (_that) {
case _StoryEnvelopeDto() when $default != null:
return $default(_that.type,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoryEnvelopeDto implements StoryEnvelopeDto {
  const _StoryEnvelopeDto({required this.type, required this.data});
  factory _StoryEnvelopeDto.fromJson(Map<String, dynamic> json) => _$StoryEnvelopeDtoFromJson(json);

@override final  String type;
@override final  FeedEntry data;

/// Create a copy of StoryEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryEnvelopeDtoCopyWith<_StoryEnvelopeDto> get copyWith => __$StoryEnvelopeDtoCopyWithImpl<_StoryEnvelopeDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoryEnvelopeDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryEnvelopeDto&&(identical(other.type, type) || other.type == type)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,data);

@override
String toString() {
  return 'StoryEnvelopeDto(type: $type, data: $data)';
}


}

/// @nodoc
abstract mixin class _$StoryEnvelopeDtoCopyWith<$Res> implements $StoryEnvelopeDtoCopyWith<$Res> {
  factory _$StoryEnvelopeDtoCopyWith(_StoryEnvelopeDto value, $Res Function(_StoryEnvelopeDto) _then) = __$StoryEnvelopeDtoCopyWithImpl;
@override @useResult
$Res call({
 String type, FeedEntry data
});


@override $FeedEntryCopyWith<$Res> get data;

}
/// @nodoc
class __$StoryEnvelopeDtoCopyWithImpl<$Res>
    implements _$StoryEnvelopeDtoCopyWith<$Res> {
  __$StoryEnvelopeDtoCopyWithImpl(this._self, this._then);

  final _StoryEnvelopeDto _self;
  final $Res Function(_StoryEnvelopeDto) _then;

/// Create a copy of StoryEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? data = null,}) {
  return _then(_StoryEnvelopeDto(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as FeedEntry,
  ));
}

/// Create a copy of StoryEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FeedEntryCopyWith<$Res> get data {
  
  return $FeedEntryCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

// dart format on
