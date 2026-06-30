//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Story {
  /// Returns a new [Story] instance.
  Story({
    required this.id,
    required this.title,
    this.description,
    this.source_,
    this.publishedAt,
  });

  int id;

  String title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? source_;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? publishedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Story &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.source_ == source_ &&
          other.publishedAt == publishedAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (title.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (source_ == null ? 0 : source_!.hashCode) +
      (publishedAt == null ? 0 : publishedAt!.hashCode);

  @override
  String toString() =>
      'Story[id=$id, title=$title, description=$description, source_=$source_, publishedAt=$publishedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'title'] = this.title;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.source_ != null) {
      json[r'source'] = this.source_;
    } else {
      json[r'source'] = null;
    }
    if (this.publishedAt != null) {
      json[r'published_at'] = this.publishedAt!.toUtc().toIso8601String();
    } else {
      json[r'published_at'] = null;
    }
    return json;
  }

  /// Returns a new [Story] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Story? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "Story[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "Story[id]" has a null value in JSON.');
        assert(json.containsKey(r'title'),
            'Required key "Story[title]" is missing from JSON.');
        assert(json[r'title'] != null,
            'Required key "Story[title]" has a null value in JSON.');
        return true;
      }());

      return Story(
        id: mapValueOfType<int>(json, r'id')!,
        title: mapValueOfType<String>(json, r'title')!,
        description: mapValueOfType<String>(json, r'description'),
        source_: mapValueOfType<String>(json, r'source'),
        publishedAt: mapDateTime(json, r'published_at', r''),
      );
    }
    return null;
  }

  static List<Story> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Story>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Story.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Story> mapFromJson(dynamic json) {
    final map = <String, Story>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Story.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Story-objects as value to a dart map
  static Map<String, List<Story>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Story>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Story.listFromJson(
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
    'title',
  };
}
