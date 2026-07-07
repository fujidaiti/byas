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

/// The archived reading list items, newest first. Read-only: the archived
/// screen has no swipe actions.

@ProviderFor(archivedReadingList)
final archivedReadingListProvider = ArchivedReadingListProvider._();

/// The archived reading list items, newest first. Read-only: the archived
/// screen has no swipe actions.

final class ArchivedReadingListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReadingListItem>>,
          List<ReadingListItem>,
          FutureOr<List<ReadingListItem>>
        >
    with
        $FutureModifier<List<ReadingListItem>>,
        $FutureProvider<List<ReadingListItem>> {
  /// The archived reading list items, newest first. Read-only: the archived
  /// screen has no swipe actions.
  ArchivedReadingListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archivedReadingListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archivedReadingListHash();

  @$internal
  @override
  $FutureProviderElement<List<ReadingListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ReadingListItem>> create(Ref ref) {
    return archivedReadingList(ref);
  }
}

String _$archivedReadingListHash() =>
    r'01e9aa9d5ccfef5a5cceb173a7ca73b8e7976ffe';

/// The saved, unarchived reading list, paginated. [build] loads the first page;
/// [loadMore] appends the next.

@ProviderFor(ReadingList)
final readingListProvider = ReadingListProvider._();

/// The saved, unarchived reading list, paginated. [build] loads the first page;
/// [loadMore] appends the next.
final class ReadingListProvider
    extends $AsyncNotifierProvider<ReadingList, PagedState<ReadingListItem>> {
  /// The saved, unarchived reading list, paginated. [build] loads the first page;
  /// [loadMore] appends the next.
  ReadingListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingListHash();

  @$internal
  @override
  ReadingList create() => ReadingList();
}

String _$readingListHash() => r'8101516aab564b30b6310dfea68eebccf15169e3';

/// The saved, unarchived reading list, paginated. [build] loads the first page;
/// [loadMore] appends the next.

abstract class _$ReadingList
    extends $AsyncNotifier<PagedState<ReadingListItem>> {
  FutureOr<PagedState<ReadingListItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<PagedState<ReadingListItem>>,
              PagedState<ReadingListItem>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PagedState<ReadingListItem>>,
                PagedState<ReadingListItem>
              >,
              AsyncValue<PagedState<ReadingListItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
