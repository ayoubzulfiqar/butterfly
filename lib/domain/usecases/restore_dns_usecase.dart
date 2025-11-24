import '../../data/repositories/dns_service.dart';

/// Use case to restore DNS to default (DHCP).
class RestoreDnsUseCase {
  final DnsService dnsService;

  RestoreDnsUseCase(this.dnsService);

  Future<void> execute(String adapter) async {
    await dnsService.restoreDns(adapter);
  }
}