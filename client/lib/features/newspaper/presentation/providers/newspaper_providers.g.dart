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

@ProviderFor(todayNewspaper)
final todayNewspaperProvider = TodayNewspaperProvider._();

final class TodayNewspaperProvider
    extends
        $FunctionalProvider<
          AsyncValue<Newspaper>,
          Newspaper,
          FutureOr<Newspaper>
        >
    with $FutureModifier<Newspaper>, $FutureProvider<Newspaper> {
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
  $FutureProviderElement<Newspaper> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Newspaper> create(Ref ref) {
    return todayNewspaper(ref);
  }
}

String _$todayNewspaperHash() => r'269e8adc6869a3f1ab692d7fc0bd702a658acdeb';
