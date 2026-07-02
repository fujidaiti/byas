//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ReadingListItem {
  /// Returns a new [ReadingListItem] instance.
  ReadingListItem({
    required this.id,
    required this.title,
    this.description,
    required this.savedAt,
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

  DateTime savedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingListItem &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.savedAt == savedAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (title.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (savedAt.hashCode);

  @override
  String toString() =>
      'ReadingListItem[id=$id, title=$title, description=$description, savedAt=$savedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'title'] = this.title;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    json[r'saved_at'] = this.savedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [ReadingListItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReadingListItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "ReadingListItem[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "ReadingListItem[id]" has a null value in JSON.');
        assert(json.containsKey(r'title'),
            'Required key "ReadingListItem[title]" is missing from JSON.');
        assert(json[r'title'] != null,
            'Required key "ReadingListItem[title]" has a null value in JSON.');
        assert(json.containsKey(r'saved_at'),
            'Required key "ReadingListItem[saved_at]" is missing from JSON.');
        assert(json[r'saved_at'] != null,
            'Required key "ReadingListItem[saved_at]" has a null value in JSON.');
        return true;
      }());

      return ReadingListItem(
        id: mapValueOfType<int>(json, r'id')!,
        title: mapValueOfType<String>(json, r'title')!,
        description: mapValueOfType<String>(json, r'description'),
        savedAt: mapDateTime(json, r'saved_at', r'')!,
      );
    }
    return null;
  }

  static List<ReadingListItem> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ReadingListItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReadingListItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReadingListItem> mapFromJson(dynamic json) {
    final map = <String, ReadingListItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReadingListItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReadingListItem-objects as value to a dart map
  static Map<String, List<ReadingListItem>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ReadingListItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReadingListItem.listFromJson(
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
    'saved_at',
  };
}
