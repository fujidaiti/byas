// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_list_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReadingListItem {

 int get id; int get resourceId; ReadingListItemKind get kind; String get title; DateTime get savedAt; String? get description;
/// Create a copy of ReadingListItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingListItemCopyWith<ReadingListItem> get copyWith => _$ReadingListItemCopyWithImpl<ReadingListItem>(this as ReadingListItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingListItem&&(identical(other.id, id) || other.id == id)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,resourceId,kind,title,savedAt,description);

@override
String toString() {
  return 'ReadingListItem(id: $id, resourceId: $resourceId, kind: $kind, title: $title, savedAt: $savedAt, description: $description)';
}


}

/// @nodoc
abstract mixin class $ReadingListItemCopyWith<$Res>  {
  factory $ReadingListItemCopyWith(ReadingListItem value, $Res Function(ReadingListItem) _then) = _$ReadingListItemCopyWithImpl;
@useResult
$Res call({
 int id, int resourceId, ReadingListItemKind kind, String title, DateTime savedAt, String? description
});




}
/// @nodoc
class _$ReadingListItemCopyWithImpl<$Res>
    implements $ReadingListItemCopyWith<$Res> {
  _$ReadingListItemCopyWithImpl(this._self, this._then);

  final ReadingListItem _self;
  final $Res Function(ReadingListItem) _then;

/// Create a copy of ReadingListItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? resourceId = null,Object? kind = null,Object? title = null,Object? savedAt = null,Object? description = freezed,}) {
  return _then(ReadingListItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ReadingListItemKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingListItem].
extension ReadingListItemPatterns on ReadingListItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingListItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingListItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingListItem value)  $default,){
final _that = this;
switch (_that) {
case _ReadingListItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingListItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingListItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int resourceId,  ReadingListItemKind kind,  String title,  DateTime savedAt,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingListItem() when $default != null:
return $default(_that.id,_that.resourceId,_that.kind,_that.title,_that.savedAt,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int resourceId,  ReadingListItemKind kind,  String title,  DateTime savedAt,  String? description)  $default,) {final _that = this;
switch (_that) {
case _ReadingListItem():
return $default(_that.id,_that.resourceId,_that.kind,_that.title,_that.savedAt,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int resourceId,  ReadingListItemKind kind,  String title,  DateTime savedAt,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _ReadingListItem() when $default != null:
return $default(_that.id,_that.resourceId,_that.kind,_that.title,_that.savedAt,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingListItem implements ReadingListItem {
  const _ReadingListItem({required this.id, required this.resourceId, required this.kind, required this.title, required this.savedAt, this.description});
  

@override final  int id;
@override final  int resourceId;
@override final  ReadingListItemKind kind;
@override final  String title;
@override final  DateTime savedAt;
@override final  String? description;

/// Create a copy of ReadingListItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingListItemCopyWith<_ReadingListItem> get copyWith => __$ReadingListItemCopyWithImpl<_ReadingListItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingListItem&&(identical(other.id, id) || other.id == id)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,resourceId,kind,title,savedAt,description);

@override
String toString() {
  return 'ReadingListItem(id: $id, resourceId: $resourceId, kind: $kind, title: $title, savedAt: $savedAt, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ReadingListItemCopyWith<$Res> implements $ReadingListItemCopyWith<$Res> {
  factory _$ReadingListItemCopyWith(_ReadingListItem value, $Res Function(_ReadingListItem) _then) = __$ReadingListItemCopyWithImpl;
@override @useResult
$Res call({
 int id, int resourceId, ReadingListItemKind kind, String title, DateTime savedAt, String? description
});




}
/// @nodoc
class __$ReadingListItemCopyWithImpl<$Res>
    implements _$ReadingListItemCopyWith<$Res> {
  __$ReadingListItemCopyWithImpl(this._self, this._then);

  final _ReadingListItem _self;
  final $Res Function(_ReadingListItem) _then;

/// Create a copy of ReadingListItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? resourceId = null,Object? kind = null,Object? title = null,Object? savedAt = null,Object? description = freezed,}) {
  return _then(_ReadingListItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ReadingListItemKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
