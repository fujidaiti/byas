import 'package:paperdoll/features/newspaper/domain/newspaper.dart';

/// Reads the daily newspaper and its stories.
abstract interface class NewspaperRepository {
  /// `GET /newspapers/today`. Throws a not-found error when no issue exists.
  Future<Newspaper> getToday();
}
