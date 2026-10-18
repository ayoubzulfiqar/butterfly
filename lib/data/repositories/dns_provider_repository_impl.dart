import 'dart:convert';
import 'dart:io';
import '../../domain/entities/dns_provider.dart';
import '../../domain/repositories/i_dns_provider_repository.dart';

/// Implementation of [IDnsProviderRepository] supplying curated enterprise
/// resolvers and storing custom user configurations.
class DnsProviderRepositoryImpl implements IDnsProviderRepository {
  final List<DnsProvider> _customProviders = [];

  static const List<DnsProvider> _builtInProviders = [
    DnsProvider(
      id: 'cloudflare',
      name: 'Cloudflare (1.1.1.1)',
      description: 'Ultra-fast recursive resolver with strict zero-logging and '
          'built-in DDoS mitigation and DNSSEC.',
      category: DnsCategory.privacy,
      features: ['No Logs', 'DNSSEC', 'Ultra Fast'],
      ipv4: ['1.1.1.1', '1.0.0.1'],
      ipv6: ['2606:4700:4700::1111', '2606:4700:4700::1001'],
    ),
    DnsProvider(
      id: 'google',
      name: 'Google Public DNS',
      description: 'Global anycast DNS infrastructure delivering high speed, '
          'resilience against spoofing, and reliable query routing.',
      category: DnsCategory.gaming,
      features: ['High Uptime', 'Global Anycast', 'DNSSEC'],
      ipv4: ['8.8.8.8', '8.8.4.4'],
      ipv6: ['2001:4860:4860::8888', '2001:4860:4860::8844'],
    ),
    DnsProvider(
      id: 'quad9',
      name: 'Quad9 Security DNS',
      description: 'Non-profit security resolver blocking malware, phishing, '
          'and spyware using real-time threat intelligence feeds.',
      category: DnsCategory.security,
      features: ['Threat Protection', 'No Logs', 'Non-Profit'],
      ipv4: ['9.9.9.9', '149.112.112.112'],
      ipv6: ['2620:fe::fe', '2620:fe::9'],
    ),
    DnsProvider(
      id: 'adguard',
      name: 'AdGuard Public DNS',
      description: 'Privacy-oriented DNS that blocks intrusive advertisements, '
          'trackers, and analytic collection scripts.',
      category: DnsCategory.privacy,
      features: ['Ad Blocking', 'Tracker Protection', 'No Logs'],
      ipv4: ['94.140.14.14', '94.140.15.15'],
      ipv6: ['2a10:50c0::ad1:ff', '2a10:50c0::ad2:ff'],
    ),
    DnsProvider(
      id: 'cleanbrowsing',
      name: 'CleanBrowsing Family',
      description: 'Family-safe filter blocking adult content, malicious '
          'domains, and enforcing SafeSearch on Google, Bing, and YouTube.',
      category: DnsCategory.family,
      features: ['Family Safe', 'Malware Filter', 'SafeSearch Enforced'],
      ipv4: ['185.228.168.168', '185.228.169.168'],
      ipv6: ['2a0d:2a00:1::', '2a0d:2a00:2::'],
    ),
    DnsProvider(
      id: 'dnssb',
      name: 'DNS.SB Uncensored',
      description: 'Fast, neutral, open-source DNS resolver committed to an '
          'uncensored and unmonitored Internet.',
      category: DnsCategory.privacy,
      features: ['No Logs', 'Uncensored', 'DNSSEC'],
      ipv4: ['185.222.222.222', '45.11.45.11'],
      ipv6: ['2a09::', '2a11::'],
    ),
    DnsProvider(
      id: 'mullvad',
      name: 'Mullvad Privacy DNS',
      description: 'Zero-logging public DNS hosted on Mullvad servers with '
          'built-in tracker and malware filtering.',
      category: DnsCategory.privacy,
      features: ['Strict Privacy', 'No Logs', 'QName Minimization'],
      ipv4: ['194.242.2.2', '194.242.2.3'],
      ipv6: ['2a07:e340::2', '2a07:e340::3'],
    ),
    DnsProvider(
      id: 'opendns',
      name: 'Cisco OpenDNS Home',
      description: 'High performance DNS with phishing protection and '
          'optional customizable web filtering.',
      category: DnsCategory.security,
      features: ['Phishing Shield', 'High Performance', 'Anycast'],
      ipv4: ['208.67.222.222', '208.67.220.220'],
      ipv6: ['2620:119:35::35', '2620:119:53::53'],
    ),
  ];

  final File? _storageFile;
  bool _loaded = false;

  DnsProviderRepositoryImpl({File? storageFile}) : _storageFile = storageFile;

  @override
  List<DnsProvider> getBuiltInProviders() => List.of(_builtInProviders);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    if (_storageFile != null && await _storageFile.exists()) {
      try {
        final content = await _storageFile.readAsString();
        final List<dynamic> decoded = jsonDecode(content) as List<dynamic>;
        _customProviders.clear();
        for (final item in decoded) {
          _customProviders.add(
            DnsProvider.fromJson(item as Map<String, dynamic>),
          );
        }
      } catch (_) {
        // Fallback to empty custom list on read failure
      }
    }
  }

  Future<void> _saveToStorage() async {
    if (_storageFile == null) return;
    try {
      final list = _customProviders.map((p) => p.toJson()).toList();
      await _storageFile.writeAsString(jsonEncode(list));
    } catch (_) {
      // Storage write error handled gracefully
    }
  }

  @override
  Future<List<DnsProvider>> getAllProviders() async {
    await _ensureLoaded();
    return [..._builtInProviders, ..._customProviders];
  }

  @override
  Future<void> addCustomProvider(DnsProvider provider) async {
    await _ensureLoaded();
    _customProviders.removeWhere((p) => p.id == provider.id);
    _customProviders.add(provider);
    await _saveToStorage();
  }

  @override
  Future<void> deleteCustomProvider(String id) async {
    await _ensureLoaded();
    _customProviders.removeWhere((p) => p.id == id);
    await _saveToStorage();
  }
}
