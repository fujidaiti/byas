// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_article_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(webArticleRepository)
final webArticleRepositoryProvider = WebArticleRepositoryProvider._();

final class WebArticleRepositoryProvider
    extends
        $FunctionalProvider<
          WebArticleRepository,
          WebArticleRepository,
          WebArticleRepository
        >
    with $Provider<WebArticleRepository> {
  WebArticleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webArticleRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webArticleRepositoryHash();

  @$internal
  @override
  $ProviderElement<WebArticleRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WebArticleRepository create(Ref ref) {
    return webArticleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebArticleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebArticleRepository>(value),
    );
  }
}

String _$webArticleRepositoryHash() =>
    r'337d49db3110d407aaf4e1bdf25bfa97fd3c2f31';

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

String _$webArticleHash() => r'e1a2f2dece73d9ad70bf5a888cd19b8c7c23d47c';

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
