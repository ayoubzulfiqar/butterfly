import '../../data/repositories/dns_service.dart';

/// Use case to change DNS servers.
class ChangeDnsUseCase {
  final DnsService dnsService;

  ChangeDnsUseCase(this.dnsService);

  Future<void> execute(String adapter, List<String> ipv4, List<String> ipv6) async {
    await dnsService.setDns(adapter, ipv4, ipv6);
  }
}