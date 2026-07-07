import 'package:paperdoll/features/newspaper/domain/newspaper.dart';

/// Reads the daily newspaper and its stories.
abstract interface class NewspaperRepository {
  /// `GET /newspapers/today` → a page of the latest issue's stories (with the
  /// issue header). Pass [cursor] to fetch the next page of stories. Throws a
  /// not-found error when no issue exists.
  Future<Newspaper> getToday({String? cursor});
}
