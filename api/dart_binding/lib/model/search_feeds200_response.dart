//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SearchFeeds200Response {
  /// Returns a new [SearchFeeds200Response] instance.
  SearchFeeds200Response({
    this.feeds = const [],
  });

  List<FeedCandidate> feeds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFeeds200Response &&
          _deepEquality.equals(other.feeds, feeds);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (feeds.hashCode);

  @override
  String toString() => 'SearchFeeds200Response[feeds=$feeds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'feeds'] = this.feeds;
    return json;
  }

  /// Returns a new [SearchFeeds200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SearchFeeds200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'feeds'),
            'Required key "SearchFeeds200Response[feeds]" is missing from JSON.');
        assert(json[r'feeds'] != null,
            'Required key "SearchFeeds200Response[feeds]" has a null value in JSON.');
        return true;
      }());

      return SearchFeeds200Response(
        feeds: FeedCandidate.listFromJson(json[r'feeds']),
      );
    }
    return null;
  }

  static List<SearchFeeds200Response> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SearchFeeds200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SearchFeeds200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SearchFeeds200Response> mapFromJson(dynamic json) {
    final map = <String, SearchFeeds200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SearchFeeds200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SearchFeeds200Response-objects as value to a dart map
  static Map<String, List<SearchFeeds200Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SearchFeeds200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SearchFeeds200Response.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'feeds',
  };
}
