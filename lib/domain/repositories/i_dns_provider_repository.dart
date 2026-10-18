import '../entities/dns_provider.dart';

/// Contract for managing built-in and custom DNS providers.
abstract class IDnsProviderRepository {
  /// Returns statically curated built-in DNS providers.
  List<DnsProvider> getBuiltInProviders();

  /// Returns all available providers (both built-in and persisted custom).
  Future<List<DnsProvider>> getAllProviders();

  /// Adds a custom user-defined DNS provider.
  Future<void> addCustomProvider(DnsProvider provider);

  /// Deletes a custom user-defined DNS provider by [id].
  Future<void> deleteCustomProvider(String id);
}
