import 'package:freezed_annotation/freezed_annotation.dart';

part 'web_clip.freezed.dart';

/// A saved web clip's details, the payload of the Web Clip Reader.
///
/// `content` is the fetched HTML body; it is null while the fetch is still
/// pending or has failed.
@freezed
abstract class WebClip with _$WebClip {
  const factory WebClip({
    required String url,
    String? title,
    String? description,
    String? content,
    int? readingListItemId,
  }) = _WebClip;
}
