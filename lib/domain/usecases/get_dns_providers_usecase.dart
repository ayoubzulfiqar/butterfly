import '../../data/models/dns_provider.dart';
import '../../data/repositories/dns_provider_repository.dart';

/// Use case to get the list of DNS providers.
class GetDnsProvidersUseCase {
  final DnsProviderRepository repository;

  GetDnsProvidersUseCase(this.repository);

  List<DnsProvider> execute() {
    return repository.getProviders();
  }
}