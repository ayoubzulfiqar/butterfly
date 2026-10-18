import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/dns_provider.dart';
import '../../domain/entities/network_adapter.dart';
import '../../domain/repositories/i_dns_provider_repository.dart';
import '../../domain/services/i_network_service.dart';

/// ViewModel managing network adapters, DNS selection, benchmarking, and cache.
class NetworkDnsViewModel extends ChangeNotifier {
  final INetworkService networkService;
  final IDnsProviderRepository repository;

  List<NetworkAdapter> _adapters = [];
  NetworkAdapter? _selectedAdapter;
  List<String> _currentDnsServers = [];
  List<DnsProvider> _providers = [];

  bool _isAdministrator = true;
  bool _isLoadingAdapters = false;
  bool _isApplyingDns = false;
  bool _isFlushingCache = false;
  bool _isPinging = false;

  String _statusMessage = '';
  bool _isErrorStatus = false;

  String _searchQuery = '';
  DnsCategory _selectedCategory = DnsCategory.all;

  NetworkDnsViewModel({
    required this.networkService,
    required this.repository,
  });

  List<NetworkAdapter> get adapters => _adapters;
  NetworkAdapter? get selectedAdapter => _selectedAdapter;
  List<String> get currentDnsServers => _currentDnsServers;
  List<DnsProvider> get providers => _providers;

  bool get isAdministrator => _isAdministrator;
  bool get isLoadingAdapters => _isLoadingAdapters;
  bool get isApplyingDns => _isApplyingDns;
  bool get isFlushingCache => _isFlushingCache;
  bool get isPinging => _isPinging;

  String get statusMessage => _statusMessage;
  bool get isErrorStatus => _isErrorStatus;

  String get searchQuery => _searchQuery;
  DnsCategory get selectedCategory => _selectedCategory;

  List<DnsProvider> get filteredProviders {
    return _providers.where((provider) {
      final matchesSearch = _searchQuery.isEmpty ||
          provider.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          provider.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == DnsCategory.all ||
          provider.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(DnsCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    _isLoadingAdapters = true;
    notifyListeners();

    try {
      _isAdministrator = await networkService.isAdministrator();
      _providers = await repository.getAllProviders();
      _adapters = await networkService.getAdapters();

      if (_adapters.isNotEmpty) {
        _selectedAdapter = _adapters.first;
        _currentDnsServers = _selectedAdapter!.dnsServers;
      }
    } catch (e) {
      _statusMessage = 'Failed to load network configuration: $e';
      _isErrorStatus = true;
      appLogger.severe('NetworkDnsViewModel', _statusMessage);
    } finally {
      _isLoadingAdapters = false;
      notifyListeners();
    }
  }

  Future<void> refreshAdapters() async {
    _isLoadingAdapters = true;
    notifyListeners();
    try {
      _adapters = await networkService.getAdapters();
      if (_selectedAdapter != null) {
        final match = _adapters.where((a) => a.name == _selectedAdapter!.name);
        if (match.isNotEmpty) {
          _selectedAdapter = match.first;
        } else if (_adapters.isNotEmpty) {
          _selectedAdapter = _adapters.first;
        } else {
          _selectedAdapter = null;
        }
      } else if (_adapters.isNotEmpty) {
        _selectedAdapter = _adapters.first;
      }

      if (_selectedAdapter != null) {
        await _fetchCurrentDns();
      }
    } catch (e) {
      _statusMessage = 'Adapter refresh failed: $e';
      _isErrorStatus = true;
    } finally {
      _isLoadingAdapters = false;
      notifyListeners();
    }
  }

  void selectAdapter(NetworkAdapter adapter) {
    _selectedAdapter = adapter;
    _currentDnsServers = adapter.dnsServers;
    notifyListeners();
    _fetchCurrentDns();
  }

  Future<void> _fetchCurrentDns() async {
    if (_selectedAdapter == null) return;
    try {
      _currentDnsServers = await networkService.getCurrentDns(
        _selectedAdapter!.name,
      );
      notifyListeners();
    } catch (e) {
      appLogger.warning('NetworkDnsViewModel', 'Error fetching DNS: $e');
    }
  }

  Future<bool> applyDns(DnsProvider provider) async {
    if (_selectedAdapter == null) {
      _statusMessage = 'No network adapter selected';
      _isErrorStatus = true;
      notifyListeners();
      return false;
    }

    _isApplyingDns = true;
    _statusMessage = '';
    notifyListeners();

    try {
      await networkService.setDns(
        _selectedAdapter!.name,
        provider.ipv4,
        provider.ipv6,
      );
      _statusMessage = 'Successfully switched DNS to ${provider.name}';
      _isErrorStatus = false;
      await _fetchCurrentDns();
      return true;
    } catch (e) {
      _statusMessage = '$e';
      _isErrorStatus = true;
      return false;
    } finally {
      _isApplyingDns = false;
      notifyListeners();
    }
  }

  Future<bool> restoreDhcp() async {
    if (_selectedAdapter == null) {
      _statusMessage = 'No network adapter selected';
      _isErrorStatus = true;
      notifyListeners();
      return false;
    }

    _isApplyingDns = true;
    _statusMessage = '';
    notifyListeners();

    try {
      await networkService.restoreDns(_selectedAdapter!.name);
      _statusMessage = 'Restored DNS settings to DHCP (Automatic)';
      _isErrorStatus = false;
      await _fetchCurrentDns();
      return true;
    } catch (e) {
      _statusMessage = '$e';
      _isErrorStatus = true;
      return false;
    } finally {
      _isApplyingDns = false;
      notifyListeners();
    }
  }

  Future<void> flushDnsCache() async {
    _isFlushingCache = true;
    _statusMessage = '';
    notifyListeners();

    try {
      await networkService.flushDnsCache();
      _statusMessage = 'DNS cache flushed successfully';
      _isErrorStatus = false;
    } catch (e) {
      _statusMessage = 'Failed to flush DNS cache: $e';
      _isErrorStatus = true;
    } finally {
      _isFlushingCache = false;
      notifyListeners();
    }
  }

  Future<void> runLatencyBenchmark() async {
    _isPinging = true;
    notifyListeners();

    try {
      final updated = <DnsProvider>[];
      for (final provider in _providers) {
        int? ping;
        if (provider.ipv4.isNotEmpty) {
          ping = await networkService.pingHost(provider.ipv4.first);
        }
        updated.add(provider.copyWith(latencyMs: ping));
      }
      _providers = updated;
    } finally {
      _isPinging = false;
      notifyListeners();
    }
  }

  Future<void> addCustomProvider(DnsProvider provider) async {
    await repository.addCustomProvider(provider);
    _providers = await repository.getAllProviders();
    notifyListeners();
  }

  Future<void> deleteCustomProvider(String id) async {
    await repository.deleteCustomProvider(id);
    _providers = await repository.getAllProviders();
    notifyListeners();
  }
}
