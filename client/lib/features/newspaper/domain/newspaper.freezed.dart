// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'newspaper.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Newspaper {

 int get id; DateTime get publishedAt; List<Story> get stories;
/// Create a copy of Newspaper
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewspaperCopyWith<Newspaper> get copyWith => _$NewspaperCopyWithImpl<Newspaper>(this as Newspaper, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Newspaper&&(identical(other.id, id) || other.id == id)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&const DeepCollectionEquality().equals(other.stories, stories));
}


@override
int get hashCode => Object.hash(runtimeType,id,publishedAt,const DeepCollectionEquality().hash(stories));

@override
String toString() {
  return 'Newspaper(id: $id, publishedAt: $publishedAt, stories: $stories)';
}


}

/// @nodoc
abstract mixin class $NewspaperCopyWith<$Res>  {
  factory $NewspaperCopyWith(Newspaper value, $Res Function(Newspaper) _then) = _$NewspaperCopyWithImpl;
@useResult
$Res call({
 int id, DateTime publishedAt, List<Story> stories
});




}
/// @nodoc
class _$NewspaperCopyWithImpl<$Res>
    implements $NewspaperCopyWith<$Res> {
  _$NewspaperCopyWithImpl(this._self, this._then);

  final Newspaper _self;
  final $Res Function(Newspaper) _then;

/// Create a copy of Newspaper
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? publishedAt = null,Object? stories = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,stories: null == stories ? _self.stories : stories // ignore: cast_nullable_to_non_nullable
as List<Story>,
  ));
}

}


/// Adds pattern-matching-related methods to [Newspaper].
extension NewspaperPatterns on Newspaper {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Newspaper value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Newspaper() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Newspaper value)  $default,){
final _that = this;
switch (_that) {
case _Newspaper():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Newspaper value)?  $default,){
final _that = this;
switch (_that) {
case _Newspaper() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  DateTime publishedAt,  List<Story> stories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Newspaper() when $default != null:
return $default(_that.id,_that.publishedAt,_that.stories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  DateTime publishedAt,  List<Story> stories)  $default,) {final _that = this;
switch (_that) {
case _Newspaper():
return $default(_that.id,_that.publishedAt,_that.stories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  DateTime publishedAt,  List<Story> stories)?  $default,) {final _that = this;
switch (_that) {
case _Newspaper() when $default != null:
return $default(_that.id,_that.publishedAt,_that.stories);case _:
  return null;

}
}

}

/// @nodoc


class _Newspaper implements Newspaper {
  const _Newspaper({required this.id, required this.publishedAt, required final  List<Story> stories}): _stories = stories;
  

@override final  int id;
@override final  DateTime publishedAt;
 final  List<Story> _stories;
@override List<Story> get stories {
  if (_stories is EqualUnmodifiableListView) return _stories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stories);
}


/// Create a copy of Newspaper
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewspaperCopyWith<_Newspaper> get copyWith => __$NewspaperCopyWithImpl<_Newspaper>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Newspaper&&(identical(other.id, id) || other.id == id)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&const DeepCollectionEquality().equals(other._stories, _stories));
}


@override
int get hashCode => Object.hash(runtimeType,id,publishedAt,const DeepCollectionEquality().hash(_stories));

@override
String toString() {
  return 'Newspaper(id: $id, publishedAt: $publishedAt, stories: $stories)';
}


}

/// @nodoc
abstract mixin class _$NewspaperCopyWith<$Res> implements $NewspaperCopyWith<$Res> {
  factory _$NewspaperCopyWith(_Newspaper value, $Res Function(_Newspaper) _then) = __$NewspaperCopyWithImpl;
@override @useResult
$Res call({
 int id, DateTime publishedAt, List<Story> stories
});




}
/// @nodoc
class __$NewspaperCopyWithImpl<$Res>
    implements _$NewspaperCopyWith<$Res> {
  __$NewspaperCopyWithImpl(this._self, this._then);

  final _Newspaper _self;
  final $Res Function(_Newspaper) _then;

/// Create a copy of Newspaper
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? publishedAt = null,Object? stories = null,}) {
  return _then(_Newspaper(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,stories: null == stories ? _self._stories : stories // ignore: cast_nullable_to_non_nullable
as List<Story>,
  ));
}


}

// dart format on
