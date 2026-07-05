//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GetWebArticle200Response {
  /// Returns a new [GetWebArticle200Response] instance.
  GetWebArticle200Response({
    required this.id,
    required this.url,
    this.title,
    this.description,
    this.content,
  });

  int id;

  String url;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? title;

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
      other is GetWebArticle200Response &&
          other.id == id &&
          other.url == url &&
          other.title == title &&
          other.description == description &&
          other.content == content;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (url.hashCode) +
      (title == null ? 0 : title!.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (content == null ? 0 : content!.hashCode);

  @override
  String toString() =>
      'GetWebArticle200Response[id=$id, url=$url, title=$title, description=$description, content=$content]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'url'] = this.url;
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
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

  /// Returns a new [GetWebArticle200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetWebArticle200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "GetWebArticle200Response[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "GetWebArticle200Response[id]" has a null value in JSON.');
        assert(json.containsKey(r'url'),
            'Required key "GetWebArticle200Response[url]" is missing from JSON.');
        assert(json[r'url'] != null,
            'Required key "GetWebArticle200Response[url]" has a null value in JSON.');
        return true;
      }());

      return GetWebArticle200Response(
        id: mapValueOfType<int>(json, r'id')!,
        url: mapValueOfType<String>(json, r'url')!,
        title: mapValueOfType<String>(json, r'title'),
        description: mapValueOfType<String>(json, r'description'),
        content: mapValueOfType<String>(json, r'content'),
      );
    }
    return null;
  }

  static List<GetWebArticle200Response> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetWebArticle200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetWebArticle200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetWebArticle200Response> mapFromJson(dynamic json) {
    final map = <String, GetWebArticle200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetWebArticle200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetWebArticle200Response-objects as value to a dart map
  static Map<String, List<GetWebArticle200Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetWebArticle200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetWebArticle200Response.listFromJson(
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
    'url',
  };
}
