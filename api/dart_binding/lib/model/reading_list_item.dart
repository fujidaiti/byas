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
    required this.resourceId,
    required this.kind,
    required this.title,
    this.description,
    required this.savedAt,
  });

  int id;

  /// The ID of the resource backing this item — the web clip ID for `web_clip`, or the feed entry ID for `feed_entry`. Use this to navigate directly to the appropriate reader.
  int resourceId;

  /// The kind of the reading list item.
  ReadingListItemKindEnum kind;

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
          other.resourceId == resourceId &&
          other.kind == kind &&
          other.title == title &&
          other.description == description &&
          other.savedAt == savedAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (resourceId.hashCode) +
      (kind.hashCode) +
      (title.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (savedAt.hashCode);

  @override
  String toString() =>
      'ReadingListItem[id=$id, resourceId=$resourceId, kind=$kind, title=$title, description=$description, savedAt=$savedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'resource_id'] = this.resourceId;
    json[r'kind'] = this.kind;
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
        assert(json.containsKey(r'resource_id'),
            'Required key "ReadingListItem[resource_id]" is missing from JSON.');
        assert(json[r'resource_id'] != null,
            'Required key "ReadingListItem[resource_id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "ReadingListItem[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "ReadingListItem[kind]" has a null value in JSON.');
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
        resourceId: mapValueOfType<int>(json, r'resource_id')!,
        kind: ReadingListItemKindEnum.fromJson(json[r'kind'])!,
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
    'resource_id',
    'kind',
    'title',
    'saved_at',
  };
}

/// The kind of the reading list item.
class ReadingListItemKindEnum {
  /// Instantiate a new enum with the provided [value].
  const ReadingListItemKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const webClip = ReadingListItemKindEnum._(r'web_clip');
  static const feedEntry = ReadingListItemKindEnum._(r'feed_entry');

  /// List of all possible values in this [enum][ReadingListItemKindEnum].
  static const values = <ReadingListItemKindEnum>[
    webClip,
    feedEntry,
  ];

  static ReadingListItemKindEnum? fromJson(dynamic value) =>
      ReadingListItemKindEnumTypeTransformer().decode(value);

  static List<ReadingListItemKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ReadingListItemKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReadingListItemKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ReadingListItemKindEnum] to String,
/// and [decode] dynamic data back to [ReadingListItemKindEnum].
class ReadingListItemKindEnumTypeTransformer {
  factory ReadingListItemKindEnumTypeTransformer() =>
      _instance ??= const ReadingListItemKindEnumTypeTransformer._();

  const ReadingListItemKindEnumTypeTransformer._();

  String encode(ReadingListItemKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ReadingListItemKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ReadingListItemKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'web_clip':
          return ReadingListItemKindEnum.webClip;
        case r'feed_entry':
          return ReadingListItemKindEnum.feedEntry;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ReadingListItemKindEnumTypeTransformer] instance.
  static ReadingListItemKindEnumTypeTransformer? _instance;
}
