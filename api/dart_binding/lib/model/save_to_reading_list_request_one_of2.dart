//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SaveToReadingListRequestOneOf2 {
  /// Returns a new [SaveToReadingListRequestOneOf2] instance.
  SaveToReadingListRequestOneOf2({
    required this.webArticleId,
  });

  /// The ID of an already-existing web article to re-save.
  int webArticleId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveToReadingListRequestOneOf2 &&
          other.webArticleId == webArticleId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (webArticleId.hashCode);

  @override
  String toString() =>
      'SaveToReadingListRequestOneOf2[webArticleId=$webArticleId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'web_article_id'] = this.webArticleId;
    return json;
  }

  /// Returns a new [SaveToReadingListRequestOneOf2] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SaveToReadingListRequestOneOf2? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'web_article_id'),
            'Required key "SaveToReadingListRequestOneOf2[web_article_id]" is missing from JSON.');
        assert(json[r'web_article_id'] != null,
            'Required key "SaveToReadingListRequestOneOf2[web_article_id]" has a null value in JSON.');
        return true;
      }());

      return SaveToReadingListRequestOneOf2(
        webArticleId: mapValueOfType<int>(json, r'web_article_id')!,
      );
    }
    return null;
  }

  static List<SaveToReadingListRequestOneOf2> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SaveToReadingListRequestOneOf2>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SaveToReadingListRequestOneOf2.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SaveToReadingListRequestOneOf2> mapFromJson(dynamic json) {
    final map = <String, SaveToReadingListRequestOneOf2>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SaveToReadingListRequestOneOf2.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SaveToReadingListRequestOneOf2-objects as value to a dart map
  static Map<String, List<SaveToReadingListRequestOneOf2>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SaveToReadingListRequestOneOf2>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SaveToReadingListRequestOneOf2.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'web_article_id',
  };
}
