import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_candidate.freezed.dart';

/// A feed discovered via search that has no local id yet and can be
/// subscribed to.
@freezed
abstract class FeedCandidate with _$FeedCandidate {
  const factory({
    required String url,
    required String title,
    String? siteUrl,
    String? iconUrl,
    String? description,
  }) = _FeedCandidate;
}
