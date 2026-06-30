//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GetTodaysNewspaper200Response {
  /// Returns a new [GetTodaysNewspaper200Response] instance.
  GetTodaysNewspaper200Response({
    required this.id,
    required this.publishedAt,
    this.stories = const [],
  });

  int id;

  DateTime publishedAt;

  List<Story> stories;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetTodaysNewspaper200Response &&
          other.id == id &&
          other.publishedAt == publishedAt &&
          _deepEquality.equals(other.stories, stories);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (publishedAt.hashCode) + (stories.hashCode);

  @override
  String toString() =>
      'GetTodaysNewspaper200Response[id=$id, publishedAt=$publishedAt, stories=$stories]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'published_at'] = this.publishedAt.toUtc().toIso8601String();
    json[r'stories'] = this.stories;
    return json;
  }

  /// Returns a new [GetTodaysNewspaper200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetTodaysNewspaper200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "GetTodaysNewspaper200Response[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "GetTodaysNewspaper200Response[id]" has a null value in JSON.');
        assert(json.containsKey(r'published_at'),
            'Required key "GetTodaysNewspaper200Response[published_at]" is missing from JSON.');
        assert(json[r'published_at'] != null,
            'Required key "GetTodaysNewspaper200Response[published_at]" has a null value in JSON.');
        assert(json.containsKey(r'stories'),
            'Required key "GetTodaysNewspaper200Response[stories]" is missing from JSON.');
        assert(json[r'stories'] != null,
            'Required key "GetTodaysNewspaper200Response[stories]" has a null value in JSON.');
        return true;
      }());

      return GetTodaysNewspaper200Response(
        id: mapValueOfType<int>(json, r'id')!,
        publishedAt: mapDateTime(json, r'published_at', r'')!,
        stories: Story.listFromJson(json[r'stories']),
      );
    }
    return null;
  }

  static List<GetTodaysNewspaper200Response> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetTodaysNewspaper200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetTodaysNewspaper200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetTodaysNewspaper200Response> mapFromJson(dynamic json) {
    final map = <String, GetTodaysNewspaper200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetTodaysNewspaper200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetTodaysNewspaper200Response-objects as value to a dart map
  static Map<String, List<GetTodaysNewspaper200Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetTodaysNewspaper200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetTodaysNewspaper200Response.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'published_at',
    'stories',
  };
}
