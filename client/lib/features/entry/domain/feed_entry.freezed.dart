// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeedEntry {

 int get id; int get feedId; String get url; String get title; String? get description; String? get content; DateTime? get publishedAt; DateTime? get snapshotAt;
/// Create a copy of FeedEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedEntryCopyWith<FeedEntry> get copyWith => _$FeedEntryCopyWithImpl<FeedEntry>(this as FeedEntry, _$identity);

  /// Serializes this FeedEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.feedId, feedId) || other.feedId == feedId)&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,feedId,url,title,description,content,publishedAt,snapshotAt);

@override
String toString() {
  return 'FeedEntry(id: $id, feedId: $feedId, url: $url, title: $title, description: $description, content: $content, publishedAt: $publishedAt, snapshotAt: $snapshotAt)';
}


}

/// @nodoc
abstract mixin class $FeedEntryCopyWith<$Res>  {
  factory $FeedEntryCopyWith(FeedEntry value, $Res Function(FeedEntry) _then) = _$FeedEntryCopyWithImpl;
@useResult
$Res call({
 int id, int feedId, String url, String title, String? description, String? content, DateTime? publishedAt, DateTime? snapshotAt
});




}
/// @nodoc
class _$FeedEntryCopyWithImpl<$Res>
    implements $FeedEntryCopyWith<$Res> {
  _$FeedEntryCopyWithImpl(this._self, this._then);

  final FeedEntry _self;
  final $Res Function(FeedEntry) _then;

/// Create a copy of FeedEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? feedId = null,Object? url = null,Object? title = null,Object? description = freezed,Object? content = freezed,Object? publishedAt = freezed,Object? snapshotAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,feedId: null == feedId ? _self.feedId : feedId // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,snapshotAt: freezed == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedEntry].
extension FeedEntryPatterns on FeedEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedEntry value)  $default,){
final _that = this;
switch (_that) {
case _FeedEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FeedEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int feedId,  String url,  String title,  String? description,  String? content,  DateTime? publishedAt,  DateTime? snapshotAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedEntry() when $default != null:
return $default(_that.id,_that.feedId,_that.url,_that.title,_that.description,_that.content,_that.publishedAt,_that.snapshotAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int feedId,  String url,  String title,  String? description,  String? content,  DateTime? publishedAt,  DateTime? snapshotAt)  $default,) {final _that = this;
switch (_that) {
case _FeedEntry():
return $default(_that.id,_that.feedId,_that.url,_that.title,_that.description,_that.content,_that.publishedAt,_that.snapshotAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int feedId,  String url,  String title,  String? description,  String? content,  DateTime? publishedAt,  DateTime? snapshotAt)?  $default,) {final _that = this;
switch (_that) {
case _FeedEntry() when $default != null:
return $default(_that.id,_that.feedId,_that.url,_that.title,_that.description,_that.content,_that.publishedAt,_that.snapshotAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeedEntry implements FeedEntry {
  const _FeedEntry({required this.id, required this.feedId, required this.url, required this.title, this.description, this.content, this.publishedAt, this.snapshotAt});
  factory _FeedEntry.fromJson(Map<String, dynamic> json) => _$FeedEntryFromJson(json);

@override final  int id;
@override final  int feedId;
@override final  String url;
@override final  String title;
@override final  String? description;
@override final  String? content;
@override final  DateTime? publishedAt;
@override final  DateTime? snapshotAt;

/// Create a copy of FeedEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedEntryCopyWith<_FeedEntry> get copyWith => __$FeedEntryCopyWithImpl<_FeedEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeedEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.feedId, feedId) || other.feedId == feedId)&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,feedId,url,title,description,content,publishedAt,snapshotAt);

@override
String toString() {
  return 'FeedEntry(id: $id, feedId: $feedId, url: $url, title: $title, description: $description, content: $content, publishedAt: $publishedAt, snapshotAt: $snapshotAt)';
}


}

/// @nodoc
abstract mixin class _$FeedEntryCopyWith<$Res> implements $FeedEntryCopyWith<$Res> {
  factory _$FeedEntryCopyWith(_FeedEntry value, $Res Function(_FeedEntry) _then) = __$FeedEntryCopyWithImpl;
@override @useResult
$Res call({
 int id, int feedId, String url, String title, String? description, String? content, DateTime? publishedAt, DateTime? snapshotAt
});




}
/// @nodoc
class __$FeedEntryCopyWithImpl<$Res>
    implements _$FeedEntryCopyWith<$Res> {
  __$FeedEntryCopyWithImpl(this._self, this._then);

  final _FeedEntry _self;
  final $Res Function(_FeedEntry) _then;

/// Create a copy of FeedEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? feedId = null,Object? url = null,Object? title = null,Object? description = freezed,Object? content = freezed,Object? publishedAt = freezed,Object? snapshotAt = freezed,}) {
  return _then(_FeedEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,feedId: null == feedId ? _self.feedId : feedId // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,snapshotAt: freezed == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
