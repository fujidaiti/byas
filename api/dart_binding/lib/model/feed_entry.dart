//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FeedEntry {
  /// Returns a new [FeedEntry] instance.
  FeedEntry({
    required this.id,
    required this.feedId,
    required this.url,
    required this.title,
    this.description,
    this.content,
    this.publishedAt,
    this.snapshotAt,
  });

  int id;

  int feedId;

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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? publishedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? snapshotAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedEntry &&
          other.id == id &&
          other.feedId == feedId &&
          other.url == url &&
          other.title == title &&
          other.description == description &&
          other.content == content &&
          other.publishedAt == publishedAt &&
          other.snapshotAt == snapshotAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (feedId.hashCode) +
      (url.hashCode) +
      (title.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (content == null ? 0 : content!.hashCode) +
      (publishedAt == null ? 0 : publishedAt!.hashCode) +
      (snapshotAt == null ? 0 : snapshotAt!.hashCode);

  @override
  String toString() =>
      'FeedEntry[id=$id, feedId=$feedId, url=$url, title=$title, description=$description, content=$content, publishedAt=$publishedAt, snapshotAt=$snapshotAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'feed_id'] = this.feedId;
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
    if (this.publishedAt != null) {
      json[r'published_at'] = this.publishedAt!.toUtc().toIso8601String();
    } else {
      json[r'published_at'] = null;
    }
    if (this.snapshotAt != null) {
      json[r'snapshot_at'] = this.snapshotAt!.toUtc().toIso8601String();
    } else {
      json[r'snapshot_at'] = null;
    }
    return json;
  }

  /// Returns a new [FeedEntry] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FeedEntry? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "FeedEntry[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "FeedEntry[id]" has a null value in JSON.');
        assert(json.containsKey(r'feed_id'),
            'Required key "FeedEntry[feed_id]" is missing from JSON.');
        assert(json[r'feed_id'] != null,
            'Required key "FeedEntry[feed_id]" has a null value in JSON.');
        assert(json.containsKey(r'url'),
            'Required key "FeedEntry[url]" is missing from JSON.');
        assert(json[r'url'] != null,
            'Required key "FeedEntry[url]" has a null value in JSON.');
        assert(json.containsKey(r'title'),
            'Required key "FeedEntry[title]" is missing from JSON.');
        assert(json[r'title'] != null,
            'Required key "FeedEntry[title]" has a null value in JSON.');
        return true;
      }());

      return FeedEntry(
        id: mapValueOfType<int>(json, r'id')!,
        feedId: mapValueOfType<int>(json, r'feed_id')!,
        url: mapValueOfType<String>(json, r'url')!,
        title: mapValueOfType<String>(json, r'title')!,
        description: mapValueOfType<String>(json, r'description'),
        content: mapValueOfType<String>(json, r'content'),
        publishedAt: mapDateTime(json, r'published_at', r''),
        snapshotAt: mapDateTime(json, r'snapshot_at', r''),
      );
    }
    return null;
  }

  static List<FeedEntry> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FeedEntry>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FeedEntry.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FeedEntry> mapFromJson(dynamic json) {
    final map = <String, FeedEntry>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FeedEntry.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FeedEntry-objects as value to a dart map
  static Map<String, List<FeedEntry>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FeedEntry>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FeedEntry.listFromJson(
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
    'feed_id',
    'url',
    'title',
  };
}
