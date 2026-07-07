//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GetFeeds200Response {
  /// Returns a new [GetFeeds200Response] instance.
  GetFeeds200Response({
    this.feeds = const [],
    this.nextCursor,
  });

  List<Feed> feeds;

  /// Opaque cursor to fetch the next page. Absent when there are no more feeds.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetFeeds200Response &&
          _deepEquality.equals(other.feeds, feeds) &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (feeds.hashCode) + (nextCursor == null ? 0 : nextCursor!.hashCode);

  @override
  String toString() =>
      'GetFeeds200Response[feeds=$feeds, nextCursor=$nextCursor]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'feeds'] = this.feeds;
    if (this.nextCursor != null) {
      json[r'next_cursor'] = this.nextCursor;
    } else {
      json[r'next_cursor'] = null;
    }
    return json;
  }

  /// Returns a new [GetFeeds200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetFeeds200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'feeds'),
            'Required key "GetFeeds200Response[feeds]" is missing from JSON.');
        assert(json[r'feeds'] != null,
            'Required key "GetFeeds200Response[feeds]" has a null value in JSON.');
        return true;
      }());

      return GetFeeds200Response(
        feeds: Feed.listFromJson(json[r'feeds']),
        nextCursor: mapValueOfType<String>(json, r'next_cursor'),
      );
    }
    return null;
  }

  static List<GetFeeds200Response> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetFeeds200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetFeeds200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetFeeds200Response> mapFromJson(dynamic json) {
    final map = <String, GetFeeds200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetFeeds200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetFeeds200Response-objects as value to a dart map
  static Map<String, List<GetFeeds200Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetFeeds200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetFeeds200Response.listFromJson(
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
