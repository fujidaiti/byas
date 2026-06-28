import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_candidate.freezed.dart';
part 'feed_candidate.g.dart';

/// A feed discovered via search that has no local id yet and can be
/// subscribed to.
@freezed
abstract class FeedCandidate with _$FeedCandidate {
  const factory FeedCandidate({
    required String url,
    required String title,
    String? siteUrl,
    String? iconUrl,
    String? description,
  }) = _FeedCandidate;

  factory FeedCandidate.fromJson(Map<String, dynamic> json) =>
      _$FeedCandidateFromJson(json);
}
