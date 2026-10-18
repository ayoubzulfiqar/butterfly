import 'dart:convert';
import 'dart:io';

import '../../core/utils/logger.dart';
import '../../domain/entities/dns_provider.dart';
import '../../domain/repositories/i_dns_provider_repository.dart';

/// Implementation of [IDnsProviderRepository] supplying curated enterprise
/// resolvers and storing custom user configurations.
class DnsProviderRepositoryImpl implements IDnsProviderRepository {
  final List<DnsProvider> _customProviders = [];
  final List<DnsProvider> _syncedRemoteProviders = [];

  static const List<DnsProvider> _builtInProviders = [
    // Anti-Sanction & Regional Circumvention
    DnsProvider(
      id: 'shecan',
      name: 'Shecan',
      description: 'Regional anti-sanction DNS circumvention service for '
          'sanctioned developer tools and services.',
      category: DnsCategory.bypass,
      features: ['Anti-Sanction', 'Developer AI', 'Gaming'],
      ipv4: ['178.22.122.100', '185.51.200.2'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'electro',
      name: 'Electro Team',
      description: 'Specialized low-latency gaming and anti-sanction resolver.',
      category: DnsCategory.bypass,
      features: ['Anti-Sanction', 'Gaming', 'FiveM', 'AI'],
      ipv4: ['78.157.42.100', '78.157.42.101'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'zeusdns',
      name: 'Zeus DNS',
      description: 'High-speed anti-sanction resolver for web and gaming.',
      category: DnsCategory.bypass,
      features: ['Anti-Sanction', 'Web', 'Gaming'],
      ipv4: ['37.32.5.60', '37.32.5.61'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'radar_game',
      name: 'Radar Game',
      description: 'Low-ping game packet optimization and anti-sanction routing.',
      category: DnsCategory.gaming,
      features: ['Low Ping', 'Gaming', 'FiveM'],
      ipv4: ['10.202.10.10', '10.202.10.11'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'asiatech',
      name: 'Asiatech',
      description: 'Regional hybrid web resolver with high availability.',
      category: DnsCategory.bypass,
      features: ['Regional', 'Web'],
      ipv4: ['194.36.174.161', '178.22.122.100'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'dynx_anti_sanctions',
      name: 'DynX Iran Anti-Sanctions',
      description: 'Anti-sanctions resolver with ad-blocking filters.',
      category: DnsCategory.bypass,
      features: ['Anti-Sanction', 'Ad Blocking'],
      ipv4: ['10.70.95.150', '10.70.95.162'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'hive_dns',
      name: 'Hive DNS',
      description: 'Developer, gaming, and media-optimized streaming resolver.',
      category: DnsCategory.gaming,
      features: ['Gaming', 'Developer', 'Spotify'],
      ipv4: ['87.107.52.11', '87.107.52.13'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'rapidgame',
      name: 'RapidGame DNS',
      description: 'Optimized gaming resolver for fast server handshakes.',
      category: DnsCategory.gaming,
      features: ['Gaming', 'Fast Handshake'],
      ipv4: ['94.182.137.166', '94.183.170.141'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'megalan',
      name: 'MegaLan',
      description: 'Optimized gaming routing for multiplayer lobbies.',
      category: DnsCategory.gaming,
      features: ['Gaming'],
      ipv4: ['95.111.55.251', '95.111.55.250'],
      ipv6: [],
    ),

    // Public, Privacy & Global Anycast
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
      id: 'opendns',
      name: 'Cisco OpenDNS Home',
      description: 'High performance DNS with phishing protection and '
          'optional customizable web filtering.',
      category: DnsCategory.security,
      features: ['Phishing Shield', 'High Performance', 'Anycast'],
      ipv4: ['208.67.222.222', '208.67.220.220'],
      ipv6: ['2620:119:35::35', '2620:119:53::53'],
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
      id: 'controld_ads',
      name: 'ControlD Ads',
      description: 'Ad-blocking and tracker blocking resolver powered by ControlD.',
      category: DnsCategory.privacy,
      features: ['Ad Blocking', 'No Trackers'],
      ipv4: ['76.76.2.2', '76.76.10.2'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'cleanbrowsing',
      name: 'CleanBrowsing Family',
      description: 'Family-safe filter blocking adult content, malicious '
          'domains, and enforcing SafeSearch on Google, Bing, and YouTube.',
      category: DnsCategory.family,
      features: ['Family Safe', 'Malware Filter', 'SafeSearch Enforced'],
      ipv4: ['185.228.168.10', '185.228.169.11'],
      ipv6: ['2a0d:2a00:1::', '2a0d:2a00:2::'],
    ),
    DnsProvider(
      id: 'dns0_eu',
      name: 'dns0.eu (European Public DNS)',
      description: 'High-security European recursive resolver strictly compliant '
          'with GDPR and EU sovereignty.',
      category: DnsCategory.privacy,
      features: ['GDPR Compliant', 'Zero Logs', 'EU Hosted'],
      ipv4: ['193.110.81.0', '185.253.5.0'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'dnswatch',
      name: 'DNS.WATCH',
      description: 'Uncensored, fast, and neutral DNS without logging.',
      category: DnsCategory.privacy,
      features: ['Uncensored', 'No Logs'],
      ipv4: ['84.200.69.80', '84.200.70.40'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'level3',
      name: 'Level 3 DNS',
      description: 'Reliable tier-1 backbone carrier resolver.',
      category: DnsCategory.gaming,
      features: ['Tier-1 Carrier', 'Anycast'],
      ipv4: ['209.244.0.3', '209.244.0.4'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'ultradns',
      name: 'UltraDNS',
      description: 'Enterprise-grade managed anycast DNS.',
      category: DnsCategory.security,
      features: ['Anycast', 'DDoS Resilient'],
      ipv4: ['156.154.70.1', '156.154.71.1'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'comodo',
      name: 'Comodo Secure DNS',
      description: 'Multi-layered security DNS blocking malicious sites.',
      category: DnsCategory.security,
      features: ['Malware Filter', 'Phishing Shield'],
      ipv4: ['8.26.56.26', '8.20.247.20'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'yandex',
      name: 'Yandex.DNS Safe',
      description: 'Protects computers from infected sites and fraudulent threats.',
      category: DnsCategory.security,
      features: ['Safe Web', 'Antivirus'],
      ipv4: ['77.88.8.8', '77.88.8.1'],
      ipv6: [],
    ),
    DnsProvider(
      id: 'shatel',
      name: 'Shatel',
      description: 'Regional ISP DNS optimized for low ping and stability.',
      category: DnsCategory.gaming,
      features: ['Regional', 'Gaming'],
      ipv4: ['129.250.35.250', '129.250.35.251'],
      ipv6: [],
    ),
  ];

  final File? _storageFile;
  bool _loaded = false;

  DnsProviderRepositoryImpl({File? storageFile}) : _storageFile = storageFile;

  static List<DnsProvider> parseRemoteCatalogJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return [];

      final List<DnsProvider> list = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final key = item['key'] as String? ?? '';
          final name = item['name'] as String? ?? key;
          final servers = List<String>.from(item['servers'] as List? ?? []);
          final tags = List<String>.from(item['tags'] as List? ?? []);

          if (key.isEmpty || servers.isEmpty) continue;

          DnsCategory cat = DnsCategory.privacy;
          if (tags.any((t) => t.toLowerCase().contains('gaming') || t.toLowerCase().contains('fivem'))) {
            cat = DnsCategory.gaming;
          } else if (tags.any((t) => t.toLowerCase().contains('iran') || t.toLowerCase().contains('sanction'))) {
            cat = DnsCategory.bypass;
          } else if (tags.any((t) => t.toLowerCase().contains('ad') || t.toLowerCase().contains('block'))) {
            cat = DnsCategory.security;
          }

          list.add(
            DnsProvider(
              id: key,
              name: name,
              description: 'Imported resolver with tags: ${tags.join(', ')}',
              category: cat,
              features: tags,
              ipv4: servers.where((s) => s != '0.0.0.0').toList(),
              ipv6: const [],
              isCustom: false,
            ),
          );
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> syncRemoteCatalog({
    String? endpoint,
  }) async {
    final targetUrl = endpoint ??
        'https://raw.githubusercontent.com/DnsChanger/dnsChanger-desktop/store/servers_DB.json';
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(targetUrl));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final parsed = parseRemoteCatalogJson(body);
        if (parsed.isNotEmpty) {
          final merged = <DnsProvider>[];
          final builtInMap = {for (final p in _builtInProviders) p.id: p};
          for (final p in parsed) {
            final builtIn = builtInMap[p.id];
            if (builtIn != null) {
              merged.add(builtIn.copyWith(
                ipv4: p.ipv4.isNotEmpty ? p.ipv4 : builtIn.ipv4,
                ipv6: p.ipv6.isNotEmpty ? p.ipv6 : builtIn.ipv6,
              ));
            } else {
              merged.add(p);
            }
          }
          _syncedRemoteProviders.clear();
          _syncedRemoteProviders.addAll(merged);
          appLogger.info(
            'DnsProviderRepository',
            'Synced ${_syncedRemoteProviders.length} providers from remote catalog',
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      appLogger.warning(
        'DnsProviderRepository',
        'Failed to sync remote catalog, using built-in catalog: $e',
      );
      return false;
    } finally {
      client?.close(force: true);
    }
  }

  @override
  List<DnsProvider> getBuiltInProviders() {
    if (_syncedRemoteProviders.isNotEmpty) {
      return List.of(_syncedRemoteProviders);
    }
    return List.of(_builtInProviders);
  }

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
    return [...getBuiltInProviders(), ..._customProviders];
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
