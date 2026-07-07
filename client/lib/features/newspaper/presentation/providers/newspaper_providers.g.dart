// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newspaper_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(newspaperRepository)
final newspaperRepositoryProvider = NewspaperRepositoryProvider._();

final class NewspaperRepositoryProvider
    extends
        $FunctionalProvider<
          NewspaperRepository,
          NewspaperRepository,
          NewspaperRepository
        >
    with $Provider<NewspaperRepository> {
  NewspaperRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newspaperRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newspaperRepositoryHash();

  @$internal
  @override
  $ProviderElement<NewspaperRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NewspaperRepository create(Ref ref) {
    return newspaperRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewspaperRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewspaperRepository>(value),
    );
  }
}

String _$newspaperRepositoryHash() =>
    r'f3f71c19d3c1de50acd534e650d868296ee40aed';

/// Today's newspaper, with its stories paginated. [build] loads the first page;
/// [loadMore] appends the next page of stories while keeping the header.

@ProviderFor(TodayNewspaper)
final todayNewspaperProvider = TodayNewspaperProvider._();

/// Today's newspaper, with its stories paginated. [build] loads the first page;
/// [loadMore] appends the next page of stories while keeping the header.
final class TodayNewspaperProvider
    extends $AsyncNotifierProvider<TodayNewspaper, TodayState> {
  /// Today's newspaper, with its stories paginated. [build] loads the first page;
  /// [loadMore] appends the next page of stories while keeping the header.
  TodayNewspaperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayNewspaperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayNewspaperHash();

  @$internal
  @override
  TodayNewspaper create() => TodayNewspaper();
}

String _$todayNewspaperHash() => r'f49a4e4c09a261c0350c22f01c7f94f6b939141b';

/// Today's newspaper, with its stories paginated. [build] loads the first page;
/// [loadMore] appends the next page of stories while keeping the header.

abstract class _$TodayNewspaper extends $AsyncNotifier<TodayState> {
  FutureOr<TodayState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TodayState>, TodayState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TodayState>, TodayState>,
              AsyncValue<TodayState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
