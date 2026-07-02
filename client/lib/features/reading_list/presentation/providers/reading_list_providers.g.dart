// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_list_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(readingListRepository)
final readingListRepositoryProvider = ReadingListRepositoryProvider._();

final class ReadingListRepositoryProvider
    extends
        $FunctionalProvider<
          ReadingListRepository,
          ReadingListRepository,
          ReadingListRepository
        >
    with $Provider<ReadingListRepository> {
  ReadingListRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingListRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingListRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReadingListRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReadingListRepository create(Ref ref) {
    return readingListRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadingListRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadingListRepository>(value),
    );
  }
}

String _$readingListRepositoryHash() =>
    r'115ada14fd69a0d3589bc2a49ffde3a02b5ea366';

@ProviderFor(readingList)
final readingListProvider = ReadingListFamily._();

final class ReadingListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReadingListItem>>,
          List<ReadingListItem>,
          FutureOr<List<ReadingListItem>>
        >
    with
        $FutureModifier<List<ReadingListItem>>,
        $FutureProvider<List<ReadingListItem>> {
  ReadingListProvider._({
    required ReadingListFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'readingListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$readingListHash();

  @override
  String toString() {
    return r'readingListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ReadingListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ReadingListItem>> create(Ref ref) {
    final argument = this.argument as String?;
    return readingList(ref, cursor: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$readingListHash() => r'2a5c9b83b6d839b437fd023767e19d8427b991fe';

final class ReadingListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ReadingListItem>>, String?> {
  ReadingListFamily._()
    : super(
        retry: null,
        name: r'readingListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReadingListProvider call({String? cursor}) =>
      ReadingListProvider._(argument: cursor, from: this);

  @override
  String toString() => r'readingListProvider';
}

@ProviderFor(webArticle)
final webArticleProvider = WebArticleFamily._();

final class WebArticleProvider
    extends
        $FunctionalProvider<
          AsyncValue<WebArticle>,
          WebArticle,
          FutureOr<WebArticle>
        >
    with $FutureModifier<WebArticle>, $FutureProvider<WebArticle> {
  WebArticleProvider._({
    required WebArticleFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'webArticleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$webArticleHash();

  @override
  String toString() {
    return r'webArticleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WebArticle> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WebArticle> create(Ref ref) {
    final argument = this.argument as int;
    return webArticle(ref, id: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WebArticleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$webArticleHash() => r'726a53a6b16e9321255f9fb8913f94747c4608f9';

final class WebArticleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WebArticle>, int> {
  WebArticleFamily._()
    : super(
        retry: null,
        name: r'webArticleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WebArticleProvider call({required int id}) =>
      WebArticleProvider._(argument: id, from: this);

  @override
  String toString() => r'webArticleProvider';
}
