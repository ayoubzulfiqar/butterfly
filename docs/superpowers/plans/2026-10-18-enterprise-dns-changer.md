# Enterprise DNS Changer & DPI Bypass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the Butterfly DNS Changer & DPI Bypass application into an enterprise-grade Windows desktop utility by eliminating critical PowerShell and process bugs, introducing a decoupled Clean Architecture, and implementing a modern Windows 11 Fluent UI with live benchmarking and diagnostics.

**Architecture:** Clean Architecture with distinct Domain, Data, and Presentation layers. Domain defines abstract contracts (`INetworkService`, `IDpiService`, `IDnsProviderRepository`) and immutable entities (`NetworkAdapter`, `DnsProvider`). Data provides both production Windows PowerShell/Process drivers and testable Mock implementations. Presentation leverages focused ChangeNotifier ViewModels consumed by a Fluent NavigationRail shell.

**Tech Stack:** Flutter Desktop (Windows), Dart 3.11+, Provider (^6.1.5), Google Fonts (Inter / Roboto), Logging (^1.3.0).

**Spec:** `docs/superpowers/specs/2026-10-18-enterprise-dns-changer-design.md`

## Global Constraints
- Target platform: Windows Desktop (with cross-platform mock fallback for test & CI environments).
- Lines of code: strictly 80 characters or fewer for all new Dart code where feasible (as per `rules.md`).
- Avoid `print` statements in production code: use `debugPrint` or route via `AppLogger`.
- Immutability for domain entities and value objects.
- PowerShell execution must never interpolate unescaped strings.
- IPv4 and IPv6 DNS addresses must be applied atomically in a single PowerShell command to prevent address overwriting.
- `goodbyedpi.exe` process must be cleanly killed when user stops it or when application exits.

## Review Focus
1. Combined IPv4 + IPv6 setting: verify both protocols are passed together to `-ServerAddresses` so IPv6 never overwrites IPv4.
2. Adapter names with spaces/symbols (e.g. "Wi-Fi 2", "Ethernet (LAN)"): verify proper quoting/escaping prevents PowerShell syntax errors.
3. Non-elevated execution: verify app detects standard user rights and surfaces non-blocking guidance instead of crashing.
4. Missing `goodbyedpi.exe`: verify app handles missing binary gracefully with diagnostic instructions rather than throwing an unhandled exception.
5. Process lifecycle & exit desync: verify DPI bypass status updates automatically if the background process crashes or terminates externally.

---

### Task 1: Core Logging & Domain Entities

**Files:**
- Create: `lib/domain/entities/network_adapter.dart`
- Create: `lib/domain/entities/dns_provider.dart`
- Create: `lib/domain/entities/dpi_bypass_mode.dart`
- Create: `lib/domain/entities/app_log_entry.dart`
- Modify: `lib/core/utils/logger.dart`
- Test: `test/unit/domain_entities_test.dart`

**Interfaces:**
- Produces: `NetworkAdapter`, `DnsProvider`, `DpiBypassMode`, `AppLogEntry`, `AppLogger` stream.

- [ ] **Step 1: Write failing unit tests for domain entities and logger stream**

```dart
// test/unit/domain_entities_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/domain/entities/network_adapter.dart';
import 'package:butterfly/domain/entities/dns_provider.dart';
import 'package:butterfly/core/utils/logger.dart';

void main() {
  test('NetworkAdapter correctly formats DNS summary', () {
    const adapter = NetworkAdapter(
      name: 'Wi-Fi',
      interfaceDescription: 'Intel Wi-Fi 6',
      isUp: true,
      isDhcp: false,
      ipv4Addresses: ['192.168.1.50'],
      ipv6Addresses: [],
      dnsServers: ['1.1.1.1', '1.0.0.1'],
    );
    expect(adapter.hasDnsConfigured, isTrue);
    expect(adapter.formattedDns, '1.1.1.1, 1.0.0.1');
  });

  test('AppLogger dispatches log entries to broadcast stream', () async {
    final entries = <AppLogEntry>[];
    final sub = appLogger.logStream.listen(entries.add);
    appLogger.info('Test', 'Hello Logger');
    await Future.delayed(const Duration(milliseconds: 20));
    expect(entries.any((e) => e.message == 'Hello Logger'), isTrue);
    await sub.cancel();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/domain_entities_test.dart`
Expected: FAIL (files not found / symbols undefined).

- [ ] **Step 3: Implement domain entities and update `logger.dart`**

Implement `NetworkAdapter`, `DnsProvider`, `DpiBypassMode`, `AppLogEntry`, and replace `print()` in `lib/core/utils/logger.dart` with an in-memory broadcast stream and `debugPrint` handler to eliminate the `avoid_print` linter warning.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/domain_entities_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/entities/ lib/core/utils/logger.dart test/unit/domain_entities_test.dart
git commit -m "feat: add domain entities and streaming app logger"
```

---

### Task 2: Service Interfaces & Data Repositories

**Files:**
- Create: `lib/domain/services/i_network_service.dart`
- Create: `lib/domain/services/i_dpi_service.dart`
- Create: `lib/domain/repositories/i_dns_provider_repository.dart`
- Create: `lib/data/repositories/dns_provider_repository_impl.dart`
- Test: `test/unit/dns_provider_repository_test.dart`

**Interfaces:**
- Consumes: `DnsProvider`, `DpiBypassMode`, `NetworkAdapter`
- Produces: `INetworkService`, `IDpiService`, `IDnsProviderRepository`, `DnsProviderRepositoryImpl`

- [ ] **Step 1: Write failing unit test for `DnsProviderRepositoryImpl`**

```dart
// test/unit/dns_provider_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/repositories/dns_provider_repository_impl.dart';

void main() {
  test('Returns built-in DNS providers including Cloudflare and Google', () {
    final repo = DnsProviderRepositoryImpl();
    final providers = repo.getBuiltInProviders();
    expect(providers.any((p) => p.name.contains('Cloudflare')), isTrue);
    expect(providers.any((p) => p.name.contains('Google')), isTrue);
    expect(providers.any((p) => p.ipv4.contains('1.1.1.1')), isTrue);
  });

  test('Supports adding and removing custom providers', () async {
    final repo = DnsProviderRepositoryImpl();
    final custom = DnsProvider(
      id: 'custom_1',
      name: 'Corporate DNS',
      description: 'Internal resolver',
      category: DnsCategory.custom,
      features: ['Internal'],
      ipv4: ['10.0.0.1'],
      ipv6: [],
      isCustom: true,
    );
    await repo.addCustomProvider(custom);
    final all = await repo.getAllProviders();
    expect(all.any((p) => p.id == 'custom_1'), isTrue);
    await repo.deleteCustomProvider('custom_1');
    final after = await repo.getAllProviders();
    expect(after.any((p) => p.id == 'custom_1'), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/dns_provider_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement domain service contracts and `DnsProviderRepositoryImpl`**

Create `i_network_service.dart`, `i_dpi_service.dart`, `i_dns_provider_repository.dart`, and implement `DnsProviderRepositoryImpl` with a curated list of enterprise resolvers (Cloudflare, Google, Quad9, AdGuard, CleanBrowsing, DNS.SB, Mullvad, OpenDNS).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/dns_provider_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/services/ lib/domain/repositories/ lib/data/repositories/ test/unit/dns_provider_repository_test.dart
git commit -m "feat: define domain service contracts and implement dns provider repository"
```

---

### Task 3: Network Service & Windows System Engine (PowerShell & Mocks)

**Files:**
- Create: `lib/data/services/windows_network_service.dart`
- Create: `lib/data/services/mock_network_service.dart`
- Test: `test/unit/network_service_test.dart`

**Interfaces:**
- Consumes: `INetworkService`, `NetworkAdapter`
- Produces: `WindowsNetworkService`, `MockNetworkService`

- [ ] **Step 1: Write failing unit test for `MockNetworkService` and command builder logic**

```dart
// test/unit/network_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/mock_network_service.dart';
import 'package:butterfly/data/services/windows_network_service.dart';

void main() {
  test('MockNetworkService simulates adapter discovery and DNS setting', () async {
    final service = MockNetworkService();
    final adapters = await service.getAdapters();
    expect(adapters.isNotEmpty, isTrue);

    final adapterName = adapters.first.name;
    await service.setDns(adapterName, ['1.1.1.1', '1.0.0.1'], ['2606:4700:4700::1111']);
    final currentDns = await service.getCurrentDns(adapterName);
    expect(currentDns, contains('1.1.1.1'));
    expect(currentDns, contains('2606:4700:4700::1111'));
  });

  test('WindowsNetworkService formats combined IPv4 and IPv6 atomic command safely', () {
    final command = WindowsNetworkService.buildSetDnsCommand(
      'Wi-Fi "Guest"',
      ['1.1.1.1', '1.0.0.1'],
      ['2606:4700:4700::1111'],
    );
    expect(command, contains(r'Wi-Fi `"Guest`"'));
    expect(command, contains(r'@("1.1.1.1","1.0.0.1","2606:4700:4700::1111")'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/network_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `WindowsNetworkService` and `MockNetworkService`**

Implement `WindowsNetworkService` with:
- Safe PowerShell argument escaping.
- Combined array `-ServerAddresses @($allIps)` to fix IPv4/IPv6 overwrite.
- Admin token elevation check via `[Security.Principal.WindowsPrincipal]`.
- Cache flushing using `ipconfig /flushdns` and `Clear-DnsClientCache`.
- Robust parsing of `Get-DnsClientServerAddress` output.
Implement `MockNetworkService` providing full in-memory simulation for unit/widget tests and Linux/Mac environments.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/network_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/services/windows_network_service.dart lib/data/services/mock_network_service.dart test/unit/network_service_test.dart
git commit -m "feat: implement windows network engine with safe powershell and mock fallback"
```

---

### Task 4: DPI Bypass Service & Process Controller

**Files:**
- Create: `lib/data/services/windows_dpi_service.dart`
- Create: `lib/data/services/mock_dpi_service.dart`
- Test: `test/unit/dpi_service_test.dart`

**Interfaces:**
- Consumes: `IDpiService`, `DpiBypassMode`
- Produces: `WindowsDpiService`, `MockDpiService`

- [ ] **Step 1: Write failing unit test for `MockDpiService` lifecycle & state streams**

```dart
// test/unit/dpi_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/mock_dpi_service.dart';
import 'package:butterfly/domain/entities/dpi_bypass_mode.dart';

void main() {
  test('MockDpiService starts and emits running state transitions', () async {
    final service = MockDpiService();
    expect(service.isRunning, isFalse);

    final states = <bool>[];
    final sub = service.runningStateStream.listen(states.add);

    await service.start(DpiBypassModes.standard);
    expect(service.isRunning, isTrue);

    await service.stop();
    expect(service.isRunning, isFalse);

    await sub.cancel();
    expect(states, [true, false]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/dpi_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `WindowsDpiService` and `MockDpiService`**

Implement:
- Binary existence checks (`isExecutableAvailable()`).
- Process spawning with non-blocking stdout/stderr stream listeners streaming to `AppLogger`.
- Process exit listener updating running state stream when terminated externally or crashed.
- Process termination with `kill()`.
- Flutter `WidgetsBindingObserver` integration to terminate child processes when the application is disposed.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/dpi_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/services/windows_dpi_service.dart lib/data/services/mock_dpi_service.dart test/unit/dpi_service_test.dart
git commit -m "feat: implement dpi bypass process management service and mock"
```

---

### Task 5: Presentation ViewModels & State Management

**Files:**
- Create: `lib/presentation/viewmodels/navigation_viewmodel.dart`
- Create: `lib/presentation/viewmodels/network_dns_viewmodel.dart`
- Create: `lib/presentation/viewmodels/dpi_viewmodel.dart`
- Create: `lib/presentation/viewmodels/diagnostics_viewmodel.dart`
- Test: `test/unit/network_dns_viewmodel_test.dart`
- Test: `test/unit/dpi_viewmodel_test.dart`

**Interfaces:**
- Consumes: `INetworkService`, `IDpiService`, `IDnsProviderRepository`
- Produces: `NavigationViewModel`, `NetworkDnsViewModel`, `DpiViewModel`, `DiagnosticsViewModel`

- [ ] **Step 1: Write failing unit tests for `NetworkDnsViewModel` and `DpiViewModel`**

```dart
// test/unit/network_dns_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/mock_network_service.dart';
import 'package:butterfly/data/repositories/dns_provider_repository_impl.dart';
import 'package:butterfly/presentation/viewmodels/network_dns_viewmodel.dart';

void main() {
  test('NetworkDnsViewModel loads adapters and selects first adapter', () async {
    final netService = MockNetworkService();
    final repo = DnsProviderRepositoryImpl();
    final vm = NetworkDnsViewModel(networkService: netService, repository: repo);

    await vm.loadInitialData();
    expect(vm.adapters.isNotEmpty, isTrue);
    expect(vm.selectedAdapter, isNotNull);
    expect(vm.currentDnsServers, isNotEmpty);
  });

  test('NetworkDnsViewModel applies DNS and updates state', () async {
    final netService = MockNetworkService();
    final repo = DnsProviderRepositoryImpl();
    final vm = NetworkDnsViewModel(networkService: netService, repository: repo);
    await vm.loadInitialData();

    final cloudflare = vm.providers.firstWhere((p) => p.name.contains('Cloudflare'));
    final success = await vm.applyDns(cloudflare);
    expect(success, isTrue);
    expect(vm.isApplyingDns, isFalse);
    expect(vm.statusMessage, contains('Cloudflare'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/network_dns_viewmodel_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement the four focused ViewModels**

Implement:
- `NavigationViewModel`: Selected index, page routing.
- `NetworkDnsViewModel`: Adapter selection, DNS application, DHCP restore, cache flushing, search filter, and latency ping runner.
- `DpiViewModel`: Mode selection, executable check, start/stop with loading guard.
- `DiagnosticsViewModel`: Subscribes to `appLogger.logStream`, stores structured log buffer, provides level filtering and clipboard export.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/network_dns_viewmodel_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/viewmodels/ test/unit/network_dns_viewmodel_test.dart
git commit -m "feat: implement modular presentation viewmodels"
```

---

### Task 6: Enterprise Theme & Shared Fluent UI Components

**Files:**
- Modify: `lib/core/themes/app_theme.dart`
- Create: `lib/presentation/widgets/fluent_card.dart`
- Create: `lib/presentation/widgets/status_badge.dart`
- Create: `lib/presentation/widgets/elevation_banner.dart`
- Create: `lib/presentation/widgets/custom_dns_dialog.dart`
- Test: `test/widget/shared_widgets_test.dart`

**Interfaces:**
- Produces: `AppTheme.fluentDark`, `AppTheme.fluentLight`, `FluentCard`, `StatusBadge`, `ElevationBanner`, `CustomDnsDialog`

- [ ] **Step 1: Write failing widget test for shared UI components**

```dart
// test/widget/shared_widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/presentation/widgets/status_badge.dart';
import 'package:butterfly/presentation/widgets/elevation_banner.dart';

void main() {
  testWidgets('StatusBadge displays label and color correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(label: 'Active', isSuccess: true),
        ),
      ),
    );
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('ElevationBanner warns when user is not administrator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElevationBanner(isElevated: false),
        ),
      ),
    );
    expect(find.textContaining('Administrator privileges'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/shared_widgets_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `app_theme.dart` and reusable Fluent UI components**

Create Windows 11 Fluent Design theme (dark slate background `#1E1E24`, elevated cards `#2B2D35`, subtle borders `#3E404D`, Fluent accent blue `#0078D4`, success emerald `#107C41`, warning amber `#D83B01`). Build `FluentCard`, `StatusBadge`, `ElevationBanner`, and `CustomDnsDialog`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/shared_widgets_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/themes/ lib/presentation/widgets/ test/widget/shared_widgets_test.dart
git commit -m "feat: implement fluent theme and shared ui components"
```

---

### Task 7: Pages & Enterprise Main Shell Screen

**Files:**
- Create: `lib/presentation/views/pages/dashboard_page.dart`
- Create: `lib/presentation/views/pages/dns_resolvers_page.dart`
- Create: `lib/presentation/views/pages/dpi_bypass_page.dart`
- Create: `lib/presentation/views/pages/diagnostics_page.dart`
- Create: `lib/presentation/views/main_shell_screen.dart`
- Modify: `lib/main.dart`
- Delete: `test/widget_test.dart`
- Test: `test/widget/main_shell_test.dart`

**Interfaces:**
- Consumes: All ViewModels, Shared widgets, `AppTheme`
- Produces: Complete desktop application view hierarchy

- [ ] **Step 1: Write failing widget test for `MainShellScreen` and navigation**

```dart
// test/widget/main_shell_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:butterfly/data/services/mock_network_service.dart';
import 'package:butterfly/data/services/mock_dpi_service.dart';
import 'package:butterfly/data/repositories/dns_provider_repository_impl.dart';
import 'package:butterfly/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/network_dns_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/dpi_viewmodel.dart';
import 'package:butterfly/presentation/viewmodels/diagnostics_viewmodel.dart';
import 'package:butterfly/presentation/views/main_shell_screen.dart';

void main() {
  testWidgets('MainShellScreen renders navigation rail and switches pages', (tester) async {
    final netService = MockNetworkService();
    final dpiService = MockDpiService();
    final repo = DnsProviderRepositoryImpl();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NavigationViewModel()),
          ChangeNotifierProvider(create: (_) => NetworkDnsViewModel(networkService: netService, repository: repo)),
          ChangeNotifierProvider(create: (_) => DpiViewModel(dpiService: dpiService)),
          ChangeNotifierProvider(create: (_) => DiagnosticsViewModel()),
        ],
        child: const MaterialApp(home: MainShellScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('DNS Resolvers'), findsOneWidget);

    // Tap DNS Resolvers
    await tester.tap(find.text('DNS Resolvers'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cloudflare'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/main_shell_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement pages, shell screen, and rewire `lib/main.dart`**

Implement:
- `DashboardPage`: Active network adapter card, current DNS server status pills, quick action cards (DHCP reset, Flush cache, Top 2 quick switches), DPI bypass status card.
- `DnsResolversPage`: Category filter chips, search input, speed benchmark runner, responsive provider cards with latency tags, IPv4/IPv6 chips, "Apply" button, "Add Custom DNS" dialog trigger.
- `DpiBypassPage`: Status hero header, `goodbyedpi.exe` presence card with instructions, mode selection cards, start/stop toggle.
- `DiagnosticsPage`: Real-time structured log stream, severity filtering, search bar, copy-all-logs button.
- `MainShellScreen`: Fluent NavigationRail, top header with elevation chip, quick flush cache button, and view switching.
- Rewire `lib/main.dart` with platform-aware service instantiation (`WindowsNetworkService` if `Platform.isWindows`, else `MockNetworkService`).
- Remove obsolete `test/widget_test.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/main_shell_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/views/ lib/main.dart test/widget/main_shell_test.dart
git rm test/widget_test.dart
git commit -m "feat: implement modern fluent desktop shell, pages, and clean di wiring"
```

---

### Task 8: Code Cleanup, Static Analysis & Full Verification

**Files:**
- Modify/Remove: any obsolete files (e.g. `lib/presentation/views/dns_changer_screen.dart`, `lib/data/repositories/dns_service.dart` if replaced, unused use cases).
- Test: All tests in `test/`

- [ ] **Step 1: Clean up unused legacy files and use cases**

Remove obsolete monolithic files that were replaced by the clean architecture (`lib/presentation/views/dns_changer_screen.dart`, `lib/presentation/viewmodels/dns_changer_viewmodel.dart`, `lib/data/repositories/dns_service.dart`, and pass-through single-line use cases).

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: 0 issues found.

- [ ] **Step 3: Run full automated test suite**

Run: `flutter test`
Expected: All unit and widget tests pass with 100% success.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove deprecated legacy files and verify clean analysis"
```
