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

@ProviderFor(ReadingList)
final readingListProvider = ReadingListFamily._();

final class ReadingListProvider
    extends $AsyncNotifierProvider<ReadingList, List<ReadingListItem>> {
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
  ReadingList create() => ReadingList();

  @override
  bool operator ==(Object other) {
    return other is ReadingListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$readingListHash() => r'386747c03b5d98f8fa10b9a993b752dadc91d552';

final class ReadingListFamily extends $Family
    with
        $ClassFamilyOverride<
          ReadingList,
          AsyncValue<List<ReadingListItem>>,
          List<ReadingListItem>,
          FutureOr<List<ReadingListItem>>,
          String?
        > {
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

abstract class _$ReadingList extends $AsyncNotifier<List<ReadingListItem>> {
  late final _$args = ref.$arg as String?;
  String? get cursor => _$args;

  FutureOr<List<ReadingListItem>> build({String? cursor});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ReadingListItem>>, List<ReadingListItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ReadingListItem>>,
                List<ReadingListItem>
              >,
              AsyncValue<List<ReadingListItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(cursor: _$args));
  }
}
