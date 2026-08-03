// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(device)
final deviceProvider = DeviceProvider._();

final class DeviceProvider extends $FunctionalProvider<Device, Device, Device>
    with $Provider<Device> {
  DeviceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceHash();

  @$internal
  @override
  $ProviderElement<Device> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Device create(Ref ref) {
    return device(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Device value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Device>(value),
    );
  }
}

String _$deviceHash() => r'758aca46274b4347387189344cc80926de6c21a3';
