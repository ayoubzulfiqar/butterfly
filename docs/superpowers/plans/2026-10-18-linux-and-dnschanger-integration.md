# Multi-Platform Linux Support & dnsChanger-desktop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable native Linux desktop support and integrate the complete feature set from `dnsChanger-desktop` (25+ anti-sanction/gaming resolvers, active censorship target benchmark, and Tools Studio: My IP, Adapter Switcher, Scheduled Shutdown).

**Architecture:** Clean Architecture with platform decoupling via `PlatformServiceFactory`, separating `LinuxNetworkService` (`resolvectl`/`nmcli`) from `WindowsNetworkService` (`netsh`/PowerShell). Tools and benchmark logic reside behind domain service interfaces (`ISystemToolsService`, `IDnsBenchmarkService`) consumed by dedicated ViewModels and rendered through Windows 11 Fluent cards in a 5-item `NavigationRail` shell.

**Tech Stack:** Flutter Desktop 3.x (Linux GTK / Windows Win32), Dart 3.x, `http` / `dart:io` sockets, `systemd-resolved` (`resolvectl`), NetworkManager (`nmcli`), Provider / ChangeNotifier.

**Spec:** [`docs/superpowers/specs/2026-10-18-linux-and-dnschanger-integration-design.md`](file:///home/sensei/Projects/flutter/butterfly/docs/superpowers/specs/2026-10-18-linux-and-dnschanger-integration-design.md)

## Global Constraints

- **Cross-Platform Safety:** Linux commands must not assume root privileges; wrap elevation-required operations in `pkexec` when non-root.
- **Input Sanitization:** All interface names must match `^[a-zA-Z0-9_\-\.:]+$` and IP inputs must validate with `InternetAddress.tryParse` to prevent shell injection.
- **Formatting Standards:** Lines $\le$ 80 characters where feasible; strict type safety; no `print` in production code; all logging via `AppLogger`.
- **Offline First:** Remote provider syncing must fail gracefully back to built-in presets without interrupting UI operations.

## Review Focus

1. **Linux interface parsing:** Ensure `ip -j` / `resolvectl` correctly extracts interfaces even when some links are down or have no IPv4.
2. **Linux shell injection prevention:** Ensure interface names or custom shutdown messages cannot escape commands via semicolons or shell operators.
3. **Censorship classification:** Ensure HTTP 403 Forbidden is distinctly classified as `blocked` rather than generic `failed`.
4. **Shutdown timer duration:** Ensure minutes/seconds conversion matches OS expectations (Windows uses seconds `/t <sec>`, Linux uses minutes `+<min>`).
5. **Multi-platform DI fallback:** Ensure running on an unexpected platform or headless test environment resolves cleanly to `MockNetworkService` / `MockDpiService`.

---

### Task 1: Linux Platform Runner & New Domain Contracts

**Files:**
- Create: `linux/` (via `flutter create --platforms=linux .`)
- Create: `lib/domain/entities/benchmark_target.dart`
- Create: `lib/domain/entities/dns_benchmark_result.dart`
- Create: `lib/domain/entities/public_ip_info.dart`
- Create: `lib/domain/entities/scheduled_shutdown_state.dart`
- Create: `lib/domain/services/i_dns_benchmark_service.dart`
- Create: `lib/domain/services/i_system_tools_service.dart`
- Test: `test/unit/new_domain_entities_test.dart`

**Interfaces:**
- Produces:
  - `class BenchmarkTarget { final String key, label, url; }`
  - `class DnsBenchmarkResult { final String providerKey, providerName, targetKey; final BenchmarkStatus status; final int latencyMs; final String? resolvedIp; }`
  - `class PublicIpInfo { final String ip; final String? country, city, isp, asn; final double? latitude, longitude; }`
  - `class ScheduledShutdownState { final bool isActive; final DateTime? targetTime; final String? message; }`
  - `abstract class IDnsBenchmarkService { Future<DnsBenchmarkResult> benchmarkServer(DnsProvider provider, BenchmarkTarget target); }`
  - `abstract class ISystemToolsService { Future<PublicIpInfo> fetchPublicIpInfo(); Future<bool> setInterfaceStatus(String name, bool enable); Future<bool> scheduleShutdown(Duration delay, {String? reason}); Future<bool> cancelShutdown(); }`

- [ ] **Step 1: Scaffold Linux platform runner**
Run: `flutter create --platforms=linux .`
Verify `linux/` folder exists and contains `CMakeLists.txt` and `my_application.cc`.

- [ ] **Step 2: Write failing unit tests for new domain entities**
In `test/unit/new_domain_entities_test.dart`, test instantiation, JSON parsing of `PublicIpInfo`, formatting of `BenchmarkTarget`, and `DnsBenchmarkResult` status classifications.

- [ ] **Step 3: Run test to verify it fails**
Run: `flutter test test/unit/new_domain_entities_test.dart`
Expected: FAIL (types not defined).

- [ ] **Step 4: Implement new domain entities & service contracts**
Create `benchmark_target.dart`, `dns_benchmark_result.dart`, `public_ip_info.dart`, `scheduled_shutdown_state.dart`, `i_dns_benchmark_service.dart`, and `i_system_tools_service.dart`.

- [ ] **Step 5: Run tests and static analysis**
Run: `flutter test test/unit/new_domain_entities_test.dart && flutter analyze`
Expected: PASS.

- [ ] **Step 6: Commit**
Run: `git add linux/ lib/domain/ test/unit/new_domain_entities_test.dart && git commit -m "feat: scaffold linux platform and define tools & benchmark domain contracts"`

---

### Task 2: Linux Network Engine & Platform Service Factory

**Files:**
- Create: `lib/data/services/linux_network_service.dart`
- Create: `lib/data/services/linux_dpi_service.dart`
- Create: `lib/data/services/platform_service_factory.dart`
- Test: `test/unit/linux_network_service_test.dart`

**Interfaces:**
- Consumes: `INetworkService`, `IDpiService`, `NetworkAdapter`, `AppLogger`
- Produces:
  - `class LinuxNetworkService implements INetworkService`
  - `class LinuxDpiService implements IDpiService`
  - `class PlatformServiceFactory { static INetworkService createNetworkService(); static IDpiService createDpiService(); }`

- [ ] **Step 1: Write failing unit tests for LinuxNetworkService**
In `test/unit/linux_network_service_test.dart`, test:
  1. `buildSetDnsCommand(interface, ips)` validates interface name and formats `resolvectl dns <iface> <ips>`.
  2. `buildResetDnsCommand(interface)` formats `resolvectl revert <iface>`.
  3. Rejection of invalid interface names containing injection characters.
  4. Parsing mock JSON output from `ip -j link` and `resolvectl dns`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/unit/linux_network_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `LinuxNetworkService`, `LinuxDpiService`, and `PlatformServiceFactory`**
Implement interface inspection via `ip -j link` / `resolvectl`, safe command execution, cache flush via `resolvectl flush-caches`, and platform detection in `PlatformServiceFactory`.

- [ ] **Step 4: Run tests to verify they pass**
Run: `flutter test test/unit/linux_network_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
Run: `git add lib/data/services/ test/unit/linux_network_service_test.dart && git commit -m "feat: implement linux network engine and platform service factory"`

---

### Task 3: Provider Catalog Expansion & Remote Sync

**Files:**
- Modify: `lib/data/repositories/dns_provider_repository_impl.dart`
- Test: `test/unit/dns_provider_repository_test.dart`

**Interfaces:**
- Consumes: `DnsProvider`, `IDnsProviderRepository`
- Produces:
  - `DnsProviderRepositoryImpl.builtinProviders` containing 25+ resolvers from `servers_DB.json`.
  - `Future<void> syncRemoteCatalog({String? url})`

- [ ] **Step 1: Write failing tests for expanded catalog & remote sync**
In `test/unit/dns_provider_repository_test.dart`, add assertions verifying:
  1. Built-in catalog includes `Shecan`, `Electro Team`, `Radar Game`, `Zeus DNS`, `Asiatech`, `AdGuard`, `dns0.eu`, etc.
  2. Tags include `Gaming`, `Web`, `AdBlock`, `Anti-Sanction`.
  3. Remote sync method parses JSON and persists to storage.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/unit/dns_provider_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Update `DnsProviderRepositoryImpl`**
Add the 25+ provider constants with tags, ratings, and IP pairs. Implement `syncRemoteCatalog` with fallback on HTTP failure.

- [ ] **Step 4: Run tests to verify they pass**
Run: `flutter test test/unit/dns_provider_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
Run: `git add lib/data/repositories/ test/unit/dns_provider_repository_test.dart && git commit -m "feat: expand provider catalog to 25+ servers with remote sync"`

---

### Task 4: Target Censorship Benchmark Engine

**Files:**
- Create: `lib/data/services/dns_benchmark_service_impl.dart`
- Test: `test/unit/dns_benchmark_service_test.dart`

**Interfaces:**
- Consumes: `IDnsBenchmarkService`, `DnsProvider`, `BenchmarkTarget`, `DnsBenchmarkResult`
- Produces:
  - `class DnsBenchmarkServiceImpl implements IDnsBenchmarkService`
  - `static List<BenchmarkTarget> get defaultTargets`

- [ ] **Step 1: Write failing tests for DnsBenchmarkService**
In `test/unit/dns_benchmark_service_test.dart`:
  1. Test DNS target domain parsing (extract hostname from `https://chatgpt.com`).
  2. Test status classification: HTTP 200 -> `reachable`, HTTP 403 -> `blocked`, timeout -> `failed`.
  3. Test benchmark execution against a simulated mock client.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/unit/dns_benchmark_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `DnsBenchmarkServiceImpl`**
Implement domain parsing, DNS lookup, HTTP probe with `Host` header, and error categorization. Provide `defaultTargets` list (ChatGPT, Claude, YouTube, Google, GitHub, Twitter/X, Discord, Wikipedia).

- [ ] **Step 4: Run tests to verify they pass**
Run: `flutter test test/unit/dns_benchmark_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
Run: `git add lib/data/services/dns_benchmark_service_impl.dart test/unit/dns_benchmark_service_test.dart && git commit -m "feat: implement target-based censorship benchmark service"`

---

### Task 5: System Tools Service & ToolsViewModel

**Files:**
- Create: `lib/data/services/system_tools_service_impl.dart`
- Create: `lib/presentation/viewmodels/tools_viewmodel.dart`
- Test: `test/unit/system_tools_test.dart`

**Interfaces:**
- Consumes: `ISystemToolsService`, `PublicIpInfo`, `ScheduledShutdownState`, `AppLogger`
- Produces:
  - `class SystemToolsServiceImpl implements ISystemToolsService`
  - `class ToolsViewModel extends ChangeNotifier`

- [ ] **Step 1: Write failing tests for SystemToolsService and ToolsViewModel**
In `test/unit/system_tools_test.dart`:
  1. Test shutdown command generation for Windows (`shutdown /s /t <sec>`) vs Linux (`shutdown -h +<min>`).
  2. Test cancel shutdown command generation for Windows (`shutdown /a`) vs Linux (`shutdown -c`).
  3. Test JSON parsing for `fetchPublicIpInfo()`.
  4. Test `ToolsViewModel` state changes (loading IP, scheduling shutdown, timer countdown).

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/unit/system_tools_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `SystemToolsServiceImpl` and `ToolsViewModel`**
Implement `SystemToolsServiceImpl` with OS command mappings and HTTP IP lookup. Implement `ToolsViewModel` with state management, active shutdown timer countdown, and error handling.

- [ ] **Step 4: Run tests to verify they pass**
Run: `flutter test test/unit/system_tools_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
Run: `git add lib/data/services/system_tools_service_impl.dart lib/presentation/viewmodels/tools_viewmodel.dart test/unit/system_tools_test.dart && git commit -m "feat: implement system tools service and tools viewmodel"`

---

### Task 6: Tools Studio UI Components

**Files:**
- Create: `lib/presentation/widgets/my_ip_card.dart`
- Create: `lib/presentation/widgets/adapter_switcher_card.dart`
- Create: `lib/presentation/widgets/scheduled_shutdown_card.dart`
- Create: `lib/presentation/views/pages/tools_page.dart`
- Test: `test/widget/tools_page_test.dart`

**Interfaces:**
- Consumes: `ToolsViewModel`, `NetworkDnsViewModel`, `FluentCard`, `StatusBadge`
- Produces:
  - `class ToolsPage extends StatelessWidget`
  - `class MyIpCard extends StatelessWidget`
  - `class AdapterSwitcherCard extends StatelessWidget`
  - `class ScheduledShutdownCard extends StatelessWidget`

- [ ] **Step 1: Write failing widget test for ToolsPage**
In `test/widget/tools_page_test.dart`, pump `ToolsPage` with `ToolsViewModel` and `NetworkDnsViewModel` in test tree and assert the 3 utility sections (Public IP, Adapter Switcher, Shutdown) render.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/widget/tools_page_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `MyIpCard`, `AdapterSwitcherCard`, `ScheduledShutdownCard`, and `ToolsPage`**
Build Fluent cards following design specs:
  - `MyIpCard`: IP display, copy button, ISP/ASN/Geo badges, refresh spinner.
  - `AdapterSwitcherCard`: Adapter list with toggle switches and "Set Target" button.
  - `ScheduledShutdownCard`: Preset chips (+15m, +30m, +1h, etc.), time input, schedule and cancel buttons.
  - `ToolsPage`: Segmented or responsive grid layout container.

- [ ] **Step 4: Run widget tests to verify they pass**
Run: `flutter test test/widget/tools_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
Run: `git add lib/presentation/widgets/ lib/presentation/views/pages/tools_page.dart test/widget/tools_page_test.dart && git commit -m "feat: create tools studio page and utility cards"`

---

### Task 7: Shell Expansion, Censorship Benchmark UI & DI Wiring

**Files:**
- Modify: `lib/presentation/views/main_shell_screen.dart`
- Modify: `lib/presentation/views/pages/dns_resolvers_page.dart`
- Modify: `lib/main.dart`
- Test: `test/widget/main_shell_test.dart`

**Interfaces:**
- Consumes: `NavigationViewModel`, `ToolsViewModel`, `NetworkDnsViewModel`, `PlatformServiceFactory`, `ToolsPage`
- Produces: 5-item `NavigationRail` shell and target benchmark controls on `DnsResolversPage`.

- [ ] **Step 1: Write failing test for 5-item shell navigation**
In `test/widget/main_shell_test.dart`, update test to verify 5 destinations (Dashboard, DNS Resolvers, DPI Bypass, Tools, Diagnostics) and switching to `ToolsPage`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/widget/main_shell_test.dart`
Expected: FAIL (shell only has 4 items).

- [ ] **Step 3: Update `MainShellScreen`, `DnsResolversPage`, and `main.dart`**
  1. Add `Tools` destination (`Icons.build_circle_rounded`) to `MainShellScreen` at index 3 (moving Diagnostics to index 4) and insert `ToolsPage` into `IndexedStack`.
  2. In `DnsResolversPage`, add the benchmark target selector dropdown (ChatGPT, Claude, YouTube, etc.) with a "Benchmark Target" button.
  3. Wire `PlatformServiceFactory`, `SystemToolsServiceImpl`, `DnsBenchmarkServiceImpl`, and `ToolsViewModel` in `lib/main.dart`.

- [ ] **Step 4: Run tests to verify they pass**
Run: `flutter test test/widget/main_shell_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
Run: `git add lib/presentation/views/ lib/main.dart test/widget/main_shell_test.dart && git commit -m "feat: expand main shell to 5 workspaces and integrate censorship benchmark ui"`

---

### Task 8: End-to-End Verification & Static Analysis

**Files:**
- All modified and created files
- Test: Full test suite

- [ ] **Step 1: Run complete test suite**
Run: `flutter test`
Expected: All unit and widget tests across all suites pass GREEN.

- [ ] **Step 2: Run static analysis**
Run: `flutter analyze`
Expected: "No issues found!".

- [ ] **Step 3: Linux build check**
Run: `flutter build linux --debug` (or dry-run compilation check).
Expected: Clean build without compilation errors.

- [ ] **Step 4: Final commit & tag**
Run: `git commit --allow-empty -m "chore: verify linux support and dnschanger integration suites pass"`
