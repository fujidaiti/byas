/// Typed errors the data layer maps transport/HTTP failures into. The
/// presentation layer pattern-matches on these to choose an error surface.
sealed class DomainError implements Exception {
  const DomainError([this.message]);

  /// Server-supplied message (`{ "message": ... }`), when available.
  final String? message;

  /// Fallback shown when [message] is null.
  String get defaultMessage;

  @override
  String toString() => 'DomainError(${message ?? defaultMessage})';
}

final class UnauthorizedError extends DomainError {
  const UnauthorizedError([super.message]);

  @override
  String get defaultMessage => 'Session expired. Please sign in again.';
}

final class NotFoundError extends DomainError {
  const NotFoundError([super.message]);

  @override
  String get defaultMessage => 'Not found.';
}

final class BadRequestError extends DomainError {
  const BadRequestError([super.message]);

  @override
  String get defaultMessage => 'Invalid request.';
}

final class ServerError extends DomainError {
  const ServerError([super.message]);

  @override
  String get defaultMessage => 'Server error. Please try again.';
}

final class NetworkError extends DomainError {
  const NetworkError([super.message]);

  @override
  String get defaultMessage => 'Network error. Check your connection.';
}

final class UnknownError extends DomainError {
  const UnknownError([super.message]);

  @override
  String get defaultMessage => 'Something went wrong.';
}

/// Best-effort human-readable text for any thrown error, used by error UIs.
String describeError(Object error) {
  if (error is DomainError) {
    return error.message ?? error.defaultMessage;
  }
  return 'Something went wrong.';
}
