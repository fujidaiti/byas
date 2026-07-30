import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:openapi/api.dart' as api;

/// A Dio interceptor that answers registered routes with canned responses and
/// records any request no route matched. When several routes match the same
/// request, the last registered one wins.
class StubServer extends Interceptor {
  StubServer();

  /// A server pre-stubbed with the three shell tabs, all empty: enough for any
  /// test to boot and navigate without stubbing anything itself.
  factory StubServer.withDefaultResponses() {
    return StubServer()
      ..onGet(
        '/newspapers/today',
        body: api.GetTodaysNewspaper200Response(
          id: 1,
          publishedAt: DateTime.utc(2026, 7, 1),
        ).toJson(),
      )
      ..onGet('/reading-list', body: api.GetReadingList200Response().toJson())
      ..onGet('/feeds', body: api.GetFeeds200Response().toJson());
  }

  final _routes = <_Route>[];

  /// `'METHOD /path'` for every request no registered route matched.
  final unmatched = <String>[];

  /// Registers a GET route. [body] is the JSON response (a `Map`/`List`).
  void onGet(String path, {int status = 200, Object? body}) =>
      _routes.add(_Route('GET', path, null, status, body));

  /// Registers a POST route. [data] is an optional expected body: omit it to
  /// match any body, or pass a `Map` to match requests whose body contains all
  /// those keys (extra keys ignored).
  void onPost(String path, {int status = 200, Object? body, Object? data}) =>
      _routes.add(_Route('POST', path, data, status, body));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final route = _routes.reversed.firstWhereOrNull(
      (r) =>
          r.method == options.method &&
          r.path == options.uri.path &&
          r.matchesBody(options.data),
    );

    if (route == null) {
      unmatched.add('${options.method} ${options.uri.path}');
      // Reject (rather than hang) so the app doesn't wait forever; the
      // teardown assertion in pumpApp — not this rejection — fails the test.
      return handler.reject(
        DioException(requestOptions: options, type: DioExceptionType.unknown),
        true,
      );
    }

    final response = Response<dynamic>(
      requestOptions: options,
      statusCode: route.status,
      data: route.body,
    );
    if (options.validateStatus(route.status)) {
      handler.resolve(response);
    } else {
      handler.reject(
        DioException(
          requestOptions: options,
          response: response,
          type: DioExceptionType.badResponse,
        ),
        // Run the app's ErrorInterceptor so the status maps to a DomainError.
        true,
      );
    }
  }
}

class _Route {
  _Route(this.method, this.path, this.data, this.status, this.body);
  final String method;
  final String path;
  final Object? data;
  final int status;
  final Object? body;

  /// Whether a request carrying [actual] as its body matches this route. A
  /// `null` [data] matches any body; a `Map` matches as a top-level subset
  /// (extra keys ignored); anything else is compared with deep equality.
  bool matchesBody(Object? actual) {
    final expected = data;
    if (expected == null) {
      return true;
    }
    if (expected is Map && actual is Map) {
      return expected.entries.every(
        (e) =>
            actual.containsKey(e.key) &&
            const DeepCollectionEquality().equals(actual[e.key], e.value),
      );
    }
    return const DeepCollectionEquality().equals(expected, actual);
  }
}
