import '../../data/repositories/dns_service.dart';

/// Use case to get current DNS configuration.
class GetCurrentDnsUseCase {
  final DnsService dnsService;

  GetCurrentDnsUseCase(this.dnsService);

  Future<String> execute(String adapter) async {
    return await dnsService.getCurrentDns(adapter);
  }
}