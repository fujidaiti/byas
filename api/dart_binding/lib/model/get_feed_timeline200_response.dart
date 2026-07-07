//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GetFeedTimeline200Response {
  /// Returns a new [GetFeedTimeline200Response] instance.
  GetFeedTimeline200Response({
    this.entries = const [],
    this.nextCursor,
  });

  List<FeedEntry> entries;

  /// Opaque cursor to fetch the next page. Absent when there are no more entries.
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
      other is GetFeedTimeline200Response &&
          _deepEquality.equals(other.entries, entries) &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (entries.hashCode) + (nextCursor == null ? 0 : nextCursor!.hashCode);

  @override
  String toString() =>
      'GetFeedTimeline200Response[entries=$entries, nextCursor=$nextCursor]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'entries'] = this.entries;
    if (this.nextCursor != null) {
      json[r'next_cursor'] = this.nextCursor;
    } else {
      json[r'next_cursor'] = null;
    }
    return json;
  }

  /// Returns a new [GetFeedTimeline200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetFeedTimeline200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'entries'),
            'Required key "GetFeedTimeline200Response[entries]" is missing from JSON.');
        assert(json[r'entries'] != null,
            'Required key "GetFeedTimeline200Response[entries]" has a null value in JSON.');
        return true;
      }());

      return GetFeedTimeline200Response(
        entries: FeedEntry.listFromJson(json[r'entries']),
        nextCursor: mapValueOfType<String>(json, r'next_cursor'),
      );
    }
    return null;
  }

  static List<GetFeedTimeline200Response> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetFeedTimeline200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetFeedTimeline200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetFeedTimeline200Response> mapFromJson(dynamic json) {
    final map = <String, GetFeedTimeline200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetFeedTimeline200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetFeedTimeline200Response-objects as value to a dart map
  static Map<String, List<GetFeedTimeline200Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetFeedTimeline200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetFeedTimeline200Response.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'entries',
  };
}
