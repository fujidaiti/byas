//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ReadLater {
  /// Returns a new [ReadLater] instance.
  ReadLater({
    required this.id,
    required this.archived,
  });

  /// The id of the reading list item.
  int id;

  /// Whether the reading list item is archived.
  bool archived;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadLater && other.id == id && other.archived == archived;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (archived.hashCode);

  @override
  String toString() => 'ReadLater[id=$id, archived=$archived]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'archived'] = this.archived;
    return json;
  }

  /// Returns a new [ReadLater] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReadLater? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "ReadLater[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "ReadLater[id]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "ReadLater[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "ReadLater[archived]" has a null value in JSON.');
        return true;
      }());

      return ReadLater(
        id: mapValueOfType<int>(json, r'id')!,
        archived: mapValueOfType<bool>(json, r'archived')!,
      );
    }
    return null;
  }

  static List<ReadLater> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ReadLater>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReadLater.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReadLater> mapFromJson(dynamic json) {
    final map = <String, ReadLater>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReadLater.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReadLater-objects as value to a dart map
  static Map<String, List<ReadLater>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ReadLater>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReadLater.listFromJson(
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
    'archived',
  };
}
