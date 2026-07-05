// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'web_article.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WebArticle {

 String get url; String? get title; String? get description; String? get content;
/// Create a copy of WebArticle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebArticleCopyWith<WebArticle> get copyWith => _$WebArticleCopyWithImpl<WebArticle>(this as WebArticle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebArticle&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,url,title,description,content);

@override
String toString() {
  return 'WebArticle(url: $url, title: $title, description: $description, content: $content)';
}


}

/// @nodoc
abstract mixin class $WebArticleCopyWith<$Res>  {
  factory $WebArticleCopyWith(WebArticle value, $Res Function(WebArticle) _then) = _$WebArticleCopyWithImpl;
@useResult
$Res call({
 String url, String? title, String? description, String? content
});




}
/// @nodoc
class _$WebArticleCopyWithImpl<$Res>
    implements $WebArticleCopyWith<$Res> {
  _$WebArticleCopyWithImpl(this._self, this._then);

  final WebArticle _self;
  final $Res Function(WebArticle) _then;

/// Create a copy of WebArticle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? title = freezed,Object? description = freezed,Object? content = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WebArticle].
extension WebArticlePatterns on WebArticle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebArticle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebArticle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebArticle value)  $default,){
final _that = this;
switch (_that) {
case _WebArticle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebArticle value)?  $default,){
final _that = this;
switch (_that) {
case _WebArticle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String? title,  String? description,  String? content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebArticle() when $default != null:
return $default(_that.url,_that.title,_that.description,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String? title,  String? description,  String? content)  $default,) {final _that = this;
switch (_that) {
case _WebArticle():
return $default(_that.url,_that.title,_that.description,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String? title,  String? description,  String? content)?  $default,) {final _that = this;
switch (_that) {
case _WebArticle() when $default != null:
return $default(_that.url,_that.title,_that.description,_that.content);case _:
  return null;

}
}

}

/// @nodoc


class _WebArticle implements WebArticle {
  const _WebArticle({required this.url, this.title, this.description, this.content});
  

@override final  String url;
@override final  String? title;
@override final  String? description;
@override final  String? content;

/// Create a copy of WebArticle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebArticleCopyWith<_WebArticle> get copyWith => __$WebArticleCopyWithImpl<_WebArticle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebArticle&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,url,title,description,content);

@override
String toString() {
  return 'WebArticle(url: $url, title: $title, description: $description, content: $content)';
}


}

/// @nodoc
abstract mixin class _$WebArticleCopyWith<$Res> implements $WebArticleCopyWith<$Res> {
  factory _$WebArticleCopyWith(_WebArticle value, $Res Function(_WebArticle) _then) = __$WebArticleCopyWithImpl;
@override @useResult
$Res call({
 String url, String? title, String? description, String? content
});




}
/// @nodoc
class __$WebArticleCopyWithImpl<$Res>
    implements _$WebArticleCopyWith<$Res> {
  __$WebArticleCopyWithImpl(this._self, this._then);

  final _WebArticle _self;
  final $Res Function(_WebArticle) _then;

/// Create a copy of WebArticle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? title = freezed,Object? description = freezed,Object? content = freezed,}) {
  return _then(_WebArticle(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
