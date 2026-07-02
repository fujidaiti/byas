//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WebArticle {
  /// Returns a new [WebArticle] instance.
  WebArticle({
    required this.url,
    required this.title,
    this.description,
    this.content,
  });

  String url;

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
  String? content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebArticle &&
          other.url == url &&
          other.title == title &&
          other.description == description &&
          other.content == content;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (url.hashCode) +
      (title.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (content == null ? 0 : content!.hashCode);

  @override
  String toString() =>
      'WebArticle[url=$url, title=$title, description=$description, content=$content]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'url'] = this.url;
    json[r'title'] = this.title;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.content != null) {
      json[r'content'] = this.content;
    } else {
      json[r'content'] = null;
    }
    return json;
  }

  /// Returns a new [WebArticle] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WebArticle? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'url'),
            'Required key "WebArticle[url]" is missing from JSON.');
        assert(json[r'url'] != null,
            'Required key "WebArticle[url]" has a null value in JSON.');
        assert(json.containsKey(r'title'),
            'Required key "WebArticle[title]" is missing from JSON.');
        assert(json[r'title'] != null,
            'Required key "WebArticle[title]" has a null value in JSON.');
        return true;
      }());

      return WebArticle(
        url: mapValueOfType<String>(json, r'url')!,
        title: mapValueOfType<String>(json, r'title')!,
        description: mapValueOfType<String>(json, r'description'),
        content: mapValueOfType<String>(json, r'content'),
      );
    }
    return null;
  }

  static List<WebArticle> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WebArticle>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WebArticle.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WebArticle> mapFromJson(dynamic json) {
    final map = <String, WebArticle>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WebArticle.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WebArticle-objects as value to a dart map
  static Map<String, List<WebArticle>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<WebArticle>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WebArticle.listFromJson(
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
    'title',
  };
}
