//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SaveToReadingListRequestOneOf {
  /// Returns a new [SaveToReadingListRequestOneOf] instance.
  SaveToReadingListRequestOneOf({
    required this.url,
    this.title,
  });

  /// The URL of the web article to save.
  String url;

  /// Optional placeholder title (e.g. the page title shared by the browser). Shown until the article is fetched; a successful fetch replaces it with the extracted title.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveToReadingListRequestOneOf &&
          other.url == url &&
          other.title == title;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (url.hashCode) + (title == null ? 0 : title!.hashCode);

  @override
  String toString() => 'SaveToReadingListRequestOneOf[url=$url, title=$title]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'url'] = this.url;
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    return json;
  }

  /// Returns a new [SaveToReadingListRequestOneOf] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SaveToReadingListRequestOneOf? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'url'),
            'Required key "SaveToReadingListRequestOneOf[url]" is missing from JSON.');
        assert(json[r'url'] != null,
            'Required key "SaveToReadingListRequestOneOf[url]" has a null value in JSON.');
        return true;
      }());

      return SaveToReadingListRequestOneOf(
        url: mapValueOfType<String>(json, r'url')!,
        title: mapValueOfType<String>(json, r'title'),
      );
    }
    return null;
  }

  static List<SaveToReadingListRequestOneOf> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SaveToReadingListRequestOneOf>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SaveToReadingListRequestOneOf.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SaveToReadingListRequestOneOf> mapFromJson(dynamic json) {
    final map = <String, SaveToReadingListRequestOneOf>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SaveToReadingListRequestOneOf.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SaveToReadingListRequestOneOf-objects as value to a dart map
  static Map<String, List<SaveToReadingListRequestOneOf>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SaveToReadingListRequestOneOf>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SaveToReadingListRequestOneOf.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'url',
  };
}
