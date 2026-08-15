import 'package:freezed_annotation/freezed_annotation.dart';

part 'web_clip.freezed.dart';

/// A saved web clip's details, the payload of the Web Clip Reader.
///
/// `content` is the fetched HTML body; it is null while the fetch is still
/// pending or has failed.
///
/// `saved` is whether the clip is in the reading list. It normally agrees with
/// `readingListItemId != null`, but the reader flips it on optimistically the
/// moment a save is tapped — before the server hands back the item id — so the
/// two diverge briefly during an in-flight save.
@freezed
abstract class WebClip with _$WebClip {
  const factory({
    required String url,
    String? title,
    String? description,
    String? content,
    int? readingListItemId,
    bool? archived,
    @Default(false) bool saved,
  }) = _WebClip;
}
