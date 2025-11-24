import '../../data/repositories/dns_service.dart';

/// Use case to get available network adapters.
class GetAdaptersUseCase {
  final DnsService dnsService;

  GetAdaptersUseCase(this.dnsService);

  Future<List<String>> execute() async {
    return await dnsService.getAdapters();
  }
}