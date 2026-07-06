// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'web_clip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WebClip {

 String get url; String? get title; String? get description; String? get content; int? get readingListItemId; bool? get archived;
/// Create a copy of WebClip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebClipCopyWith<WebClip> get copyWith => _$WebClipCopyWithImpl<WebClip>(this as WebClip, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebClip&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.readingListItemId, readingListItemId) || other.readingListItemId == readingListItemId)&&(identical(other.archived, archived) || other.archived == archived));
}


@override
int get hashCode => Object.hash(runtimeType,url,title,description,content,readingListItemId,archived);

@override
String toString() {
  return 'WebClip(url: $url, title: $title, description: $description, content: $content, readingListItemId: $readingListItemId, archived: $archived)';
}


}

/// @nodoc
abstract mixin class $WebClipCopyWith<$Res>  {
  factory $WebClipCopyWith(WebClip value, $Res Function(WebClip) _then) = _$WebClipCopyWithImpl;
@useResult
$Res call({
 String url, String? title, String? description, String? content, int? readingListItemId, bool? archived
});




}
/// @nodoc
class _$WebClipCopyWithImpl<$Res>
    implements $WebClipCopyWith<$Res> {
  _$WebClipCopyWithImpl(this._self, this._then);

  final WebClip _self;
  final $Res Function(WebClip) _then;

/// Create a copy of WebClip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? title = freezed,Object? description = freezed,Object? content = freezed,Object? readingListItemId = freezed,Object? archived = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,readingListItemId: freezed == readingListItemId ? _self.readingListItemId : readingListItemId // ignore: cast_nullable_to_non_nullable
as int?,archived: freezed == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [WebClip].
extension WebClipPatterns on WebClip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebClip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebClip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebClip value)  $default,){
final _that = this;
switch (_that) {
case _WebClip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebClip value)?  $default,){
final _that = this;
switch (_that) {
case _WebClip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String? title,  String? description,  String? content,  int? readingListItemId,  bool? archived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebClip() when $default != null:
return $default(_that.url,_that.title,_that.description,_that.content,_that.readingListItemId,_that.archived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String? title,  String? description,  String? content,  int? readingListItemId,  bool? archived)  $default,) {final _that = this;
switch (_that) {
case _WebClip():
return $default(_that.url,_that.title,_that.description,_that.content,_that.readingListItemId,_that.archived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String? title,  String? description,  String? content,  int? readingListItemId,  bool? archived)?  $default,) {final _that = this;
switch (_that) {
case _WebClip() when $default != null:
return $default(_that.url,_that.title,_that.description,_that.content,_that.readingListItemId,_that.archived);case _:
  return null;

}
}

}

/// @nodoc


class _WebClip implements WebClip {
  const _WebClip({required this.url, this.title, this.description, this.content, this.readingListItemId, this.archived});
  

@override final  String url;
@override final  String? title;
@override final  String? description;
@override final  String? content;
@override final  int? readingListItemId;
@override final  bool? archived;

/// Create a copy of WebClip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebClipCopyWith<_WebClip> get copyWith => __$WebClipCopyWithImpl<_WebClip>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebClip&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.readingListItemId, readingListItemId) || other.readingListItemId == readingListItemId)&&(identical(other.archived, archived) || other.archived == archived));
}


@override
int get hashCode => Object.hash(runtimeType,url,title,description,content,readingListItemId,archived);

@override
String toString() {
  return 'WebClip(url: $url, title: $title, description: $description, content: $content, readingListItemId: $readingListItemId, archived: $archived)';
}


}

/// @nodoc
abstract mixin class _$WebClipCopyWith<$Res> implements $WebClipCopyWith<$Res> {
  factory _$WebClipCopyWith(_WebClip value, $Res Function(_WebClip) _then) = __$WebClipCopyWithImpl;
@override @useResult
$Res call({
 String url, String? title, String? description, String? content, int? readingListItemId, bool? archived
});




}
/// @nodoc
class __$WebClipCopyWithImpl<$Res>
    implements _$WebClipCopyWith<$Res> {
  __$WebClipCopyWithImpl(this._self, this._then);

  final _WebClip _self;
  final $Res Function(_WebClip) _then;

/// Create a copy of WebClip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? title = freezed,Object? description = freezed,Object? content = freezed,Object? readingListItemId = freezed,Object? archived = freezed,}) {
  return _then(_WebClip(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,readingListItemId: freezed == readingListItemId ? _self.readingListItemId : readingListItemId // ignore: cast_nullable_to_non_nullable
as int?,archived: freezed == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
