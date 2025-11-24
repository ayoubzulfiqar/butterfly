import '../models/dns_provider.dart';

/// Repository for DNS providers data.
class DnsProviderRepository {
  /// Returns a list of available DNS providers.
  List<DnsProvider> getProviders() {
    return [
      DnsProvider(
        name: 'Cloudflare',
        description: 'Cloudflare DNS is an enterprise-grade authoritative DNS service that offers the fastest response time, unparalleled redundancy, and advanced security with built-in DDoS mitigation and DNSSEC.',
        features: ['No-Logging policy', 'Reliable and fast DNS'],
        ipv4: ['1.1.1.1', '1.0.0.1'],
        ipv6: ['2606:4700:4700::1111', '2606:4700:4700::1001'],
      ),
      DnsProvider(
        name: 'Google Public DNS',
        description: 'Google Public DNS functions as a recursive name server. It promises three core benefits including faster browsing experience, improved security, and accurate results without redirects.',
        features: ['Fast and reliable DNS'],
        ipv4: ['8.8.8.8', '8.8.4.4'],
        ipv6: ['2001:4860:4860::8888', '2001:4860:4860::8844'],
      ),
      DnsProvider(
        name: 'Quad9',
        description: 'Quad9 routes your DNS queries through a secure network of servers around the globe. The system uses threat intelligence from more than a dozen of the industry\'s leading cyber security companies to give a real-time perspective on what websites are safe and what sites are known to include malware or other threats.',
        features: ['No-Logging policy', 'Prevent access to malicious websites'],
        ipv4: ['9.9.9.9', '149.112.112.112'],
        ipv6: ['2620:fe::fe', '2620:fe::9'],
      ),
      DnsProvider(
        name: 'CleanBrowsing',
        description: 'CleanBrowsing DNS service allows you to control what can and cannot be accessed on your network. Loved by schools, municipalities, and parents to create safe browsing experiences for kids.',
        features: ['Prevent access to malicious websites'],
        ipv4: ['185.228.168.9', '185.228.169.9'],
        ipv6: ['2a0d:2a00:1::2', '2a0d:2a00:2::2'],
      ),
      DnsProvider(
        name: 'DNS.SB',
        description: 'DNS.SB provides extremely fast and stable DNS resolver services to browse a faster, more private Internet.',
        features: ['No-Logging policy', 'Open-source reliable and fast DNS'],
        ipv4: ['185.222.222.222', '45.11.45.11'],
        ipv6: ['2a09::', '2a11::'],
      ),
      // Add more providers as needed
    ];
  }
}