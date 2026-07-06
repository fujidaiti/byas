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
    required this.resourceId,
    required this.kind,
    required this.title,
    this.description,
    this.source_,
    this.publishedAt,
    this.readLater,
  });

  int id;

  /// The ID of the resource backing this story. Use this to navigate directly to the appropriate reader.
  int resourceId;

  /// The kind of the resource backing this story.
  StoryKindEnum kind;

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

  /// The reading list item backing this story, if it is saved in the reading list. Absent when the story is not saved.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ReadLater? readLater;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Story &&
          other.id == id &&
          other.resourceId == resourceId &&
          other.kind == kind &&
          other.title == title &&
          other.description == description &&
          other.source_ == source_ &&
          other.publishedAt == publishedAt &&
          other.readLater == readLater;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (resourceId.hashCode) +
      (kind.hashCode) +
      (title.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (source_ == null ? 0 : source_!.hashCode) +
      (publishedAt == null ? 0 : publishedAt!.hashCode) +
      (readLater == null ? 0 : readLater!.hashCode);

  @override
  String toString() =>
      'Story[id=$id, resourceId=$resourceId, kind=$kind, title=$title, description=$description, source_=$source_, publishedAt=$publishedAt, readLater=$readLater]';

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
    if (this.readLater != null) {
      json[r'read_later'] = this.readLater;
    } else {
      json[r'read_later'] = null;
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
        assert(json.containsKey(r'resource_id'),
            'Required key "Story[resource_id]" is missing from JSON.');
        assert(json[r'resource_id'] != null,
            'Required key "Story[resource_id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "Story[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "Story[kind]" has a null value in JSON.');
        assert(json.containsKey(r'title'),
            'Required key "Story[title]" is missing from JSON.');
        assert(json[r'title'] != null,
            'Required key "Story[title]" has a null value in JSON.');
        return true;
      }());

      return Story(
        id: mapValueOfType<int>(json, r'id')!,
        resourceId: mapValueOfType<int>(json, r'resource_id')!,
        kind: StoryKindEnum.fromJson(json[r'kind'])!,
        title: mapValueOfType<String>(json, r'title')!,
        description: mapValueOfType<String>(json, r'description'),
        source_: mapValueOfType<String>(json, r'source'),
        publishedAt: mapDateTime(json, r'published_at', r''),
        readLater: ReadLater.fromJson(json[r'read_later']),
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
    'resource_id',
    'kind',
    'title',
  };
}

/// The kind of the resource backing this story.
class StoryKindEnum {
  /// Instantiate a new enum with the provided [value].
  const StoryKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const webClip = StoryKindEnum._(r'web_clip');
  static const feedEntry = StoryKindEnum._(r'feed_entry');

  /// List of all possible values in this [enum][StoryKindEnum].
  static const values = <StoryKindEnum>[
    webClip,
    feedEntry,
  ];

  static StoryKindEnum? fromJson(dynamic value) =>
      StoryKindEnumTypeTransformer().decode(value);

  static List<StoryKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoryKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoryKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [StoryKindEnum] to String,
/// and [decode] dynamic data back to [StoryKindEnum].
class StoryKindEnumTypeTransformer {
  factory StoryKindEnumTypeTransformer() =>
      _instance ??= const StoryKindEnumTypeTransformer._();

  const StoryKindEnumTypeTransformer._();

  String encode(StoryKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a StoryKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  StoryKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'web_clip':
          return StoryKindEnum.webClip;
        case r'feed_entry':
          return StoryKindEnum.feedEntry;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [StoryKindEnumTypeTransformer] instance.
  static StoryKindEnumTypeTransformer? _instance;
}
