//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GetReadingListItem200Response {
  /// Returns a new [GetReadingListItem200Response] instance.
  GetReadingListItem200Response({
    required this.id,
    required this.kind,
    required this.archived,
    required this.savedAt,
    required this.attributes,
  });

  int id;

  /// The kind of the reading list item.
  GetReadingListItem200ResponseKindEnum kind;

  bool archived;

  DateTime savedAt;

  WebArticle attributes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetReadingListItem200Response &&
          other.id == id &&
          other.kind == kind &&
          other.archived == archived &&
          other.savedAt == savedAt &&
          other.attributes == attributes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (kind.hashCode) +
      (archived.hashCode) +
      (savedAt.hashCode) +
      (attributes.hashCode);

  @override
  String toString() =>
      'GetReadingListItem200Response[id=$id, kind=$kind, archived=$archived, savedAt=$savedAt, attributes=$attributes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    json[r'archived'] = this.archived;
    json[r'saved_at'] = this.savedAt.toUtc().toIso8601String();
    json[r'attributes'] = this.attributes;
    return json;
  }

  /// Returns a new [GetReadingListItem200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetReadingListItem200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "GetReadingListItem200Response[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "GetReadingListItem200Response[id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "GetReadingListItem200Response[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "GetReadingListItem200Response[kind]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "GetReadingListItem200Response[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "GetReadingListItem200Response[archived]" has a null value in JSON.');
        assert(json.containsKey(r'saved_at'),
            'Required key "GetReadingListItem200Response[saved_at]" is missing from JSON.');
        assert(json[r'saved_at'] != null,
            'Required key "GetReadingListItem200Response[saved_at]" has a null value in JSON.');
        assert(json.containsKey(r'attributes'),
            'Required key "GetReadingListItem200Response[attributes]" is missing from JSON.');
        assert(json[r'attributes'] != null,
            'Required key "GetReadingListItem200Response[attributes]" has a null value in JSON.');
        return true;
      }());

      return GetReadingListItem200Response(
        id: mapValueOfType<int>(json, r'id')!,
        kind: GetReadingListItem200ResponseKindEnum.fromJson(json[r'kind'])!,
        archived: mapValueOfType<bool>(json, r'archived')!,
        savedAt: mapDateTime(json, r'saved_at', r'')!,
        attributes: WebArticle.fromJson(json[r'attributes'])!,
      );
    }
    return null;
  }

  static List<GetReadingListItem200Response> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetReadingListItem200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetReadingListItem200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetReadingListItem200Response> mapFromJson(dynamic json) {
    final map = <String, GetReadingListItem200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetReadingListItem200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetReadingListItem200Response-objects as value to a dart map
  static Map<String, List<GetReadingListItem200Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetReadingListItem200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetReadingListItem200Response.listFromJson(
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
    'kind',
    'archived',
    'saved_at',
    'attributes',
  };
}

/// The kind of the reading list item.
class GetReadingListItem200ResponseKindEnum {
  /// Instantiate a new enum with the provided [value].
  const GetReadingListItem200ResponseKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const webArticle =
      GetReadingListItem200ResponseKindEnum._(r'web_article');

  /// List of all possible values in this [enum][GetReadingListItem200ResponseKindEnum].
  static const values = <GetReadingListItem200ResponseKindEnum>[
    webArticle,
  ];

  static GetReadingListItem200ResponseKindEnum? fromJson(dynamic value) =>
      GetReadingListItem200ResponseKindEnumTypeTransformer().decode(value);

  static List<GetReadingListItem200ResponseKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetReadingListItem200ResponseKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetReadingListItem200ResponseKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [GetReadingListItem200ResponseKindEnum] to String,
/// and [decode] dynamic data back to [GetReadingListItem200ResponseKindEnum].
class GetReadingListItem200ResponseKindEnumTypeTransformer {
  factory GetReadingListItem200ResponseKindEnumTypeTransformer() =>
      _instance ??=
          const GetReadingListItem200ResponseKindEnumTypeTransformer._();

  const GetReadingListItem200ResponseKindEnumTypeTransformer._();

  String encode(GetReadingListItem200ResponseKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a GetReadingListItem200ResponseKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  GetReadingListItem200ResponseKindEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'web_article':
          return GetReadingListItem200ResponseKindEnum.webArticle;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [GetReadingListItem200ResponseKindEnumTypeTransformer] instance.
  static GetReadingListItem200ResponseKindEnumTypeTransformer? _instance;
}
