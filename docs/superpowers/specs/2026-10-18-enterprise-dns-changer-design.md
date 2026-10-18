# Specification: Enterprise DNS Changer & DPI Bypass Overhaul

**Date:** 2026-10-18  
**Role:** Senior Flutter Engineer & System Architect  
**Project:** Butterfly (DNS Changer & DPI Bypass for Windows Desktop)  
**Status:** Approved  

---

## 1. Executive Summary & Goals

The Butterfly application is a Windows desktop tool built with Flutter for switching network DNS resolvers and controlling GoodbyeDPI for Deep Packet Inspection bypass. 

The existing codebase suffered from critical operational bugs (IPv6 DNS overwriting IPv4, process desynchronization, unescaped PowerShell commands), lack of administrative elevation awareness, dead architecture wiring (unused ProxyProviders, tightly coupled single-file ViewModels), and an unpolished Android-style mobile layout running on Windows desktop.

This specification documents the enterprise-grade architectural overhaul and UI/UX rewrite to achieve:
1. **Rock-solid System Reliability**: Safe PowerShell execution combining IPv4 and IPv6 into atomic commands, proper escaping, and automatic DNS cache flushing.
2. **Elevated Token / Administrator Awareness**: Automatic detection of Windows Administrator rights with actionable guidance.
3. **Decoupled Clean Architecture**: SOLID-compliant separation across Domain, Data, and Presentation layers using injectable interfaces and isolated ViewModels.
4. **Resilient Process Management**: Real-time process tracking for `goodbyedpi.exe`, exit code stream handling, lifecycle observers to prevent orphan processes, and binary presence detection.
5. **Modern Windows 11 Fluent UI/UX**: Responsive desktop navigation rail, live adapter telemetry, DNS provider catalog with latency benchmarking, custom DNS support, and a structured diagnostics console.
6. **Cross-Platform & Test Readiness**: Cross-platform fallback/mock system engines ensuring unit and widget tests pass deterministically on CI and Linux/macOS environments.

---

## 2. Root Cause Analysis of Codebase Bugs

| Issue | Existing Implementation | Consequence & Impact | Enterprise Solution |
| :--- | :--- | :--- | :--- |
| **IPv4 Overwrite Bug** | `Set-DnsClientServerAddress` executed sequentially for IPv4 then IPv6 | The second command replaces the adapter's DNS list with only IPv6, wiping out IPv4 | Execute a single atomic command with combined server array: `-ServerAddresses @($allIps)` |
| **PowerShell Injection & Quoting** | Direct interpolation: `"$adapter"` without escaping | Single quotes or special characters in adapter names cause runtime syntax errors or security holes | Sanitize and escape adapter strings (`adapter.replaceAll('"', '`"')`) |
| **Zombie Process & Desync** | `_dpiProcess` tracking with no parent process termination hook; no error dispatch to UI | Closing app leaves GoodbyeDPI running in background; crash in GoodbyeDPI leaves UI stuck in "Running" state | Implement `WidgetsBindingObserver` for auto-cleanup on app exit; bind `exitCode` future to ViewModel state |
| **Missing Admin Rights** | No check for elevation at startup | Operations fail silently or throw raw "Access Denied" exceptions | Detect elevation via PowerShell `[Security.Principal.WindowsPrincipal]` and surface persistent visual banner |
| **Dead Dependency Wiring** | 7 `ProxyProvider` instances in `main.dart` never injected into ViewModel | Dead code, confusing dependency graph, untestable ViewModel | Refactor ViewModels into focused, testable classes injected cleanly via `ChangeNotifierProvider` |
| **Broken Tests & Lint Issues** | `test/widget_test.dart` checks for counter; `logger.dart` uses `print` | Test suite fails (`flutter test`); static analysis flags linter warnings (`flutter analyze`) | Provide unit tests for repositories/services and widget tests for screens; route logs through `debugPrint`/stream |

---

## 3. System Architecture & Component Design

### 3.1 Domain Layer (`lib/domain/`)

#### Entities & Models
* **`NetworkAdapter`** (`lib/domain/entities/network_adapter.dart`):
  * `id`: String identifier (interface index or alias)
  * `name`: Display name (e.g., "Wi-Fi", "Ethernet")
  * `interfaceDescription`: Hardware adapter name
  * `status`: Adapter status (`up`, `down`, `disconnected`)
  * `isDhcp`: Boolean indicating whether DNS is automatically obtained via DHCP
  * `ipv4Addresses`: List of assigned IPv4 addresses
  * `ipv6Addresses`: List of assigned IPv6 addresses
  * `dnsServers`: Structured list of configured DNS server IPs (both IPv4 and IPv6)
* **`DnsProvider`** (`lib/domain/entities/dns_provider.dart`):
  * `id`: Unique identifier
  * `name`: Provider name (e.g., "Cloudflare")
  * `description`: High-level explanation of features and privacy policy
  * `category`: Categorization enum (`privacy`, `security`, `gaming`, `family`, `custom`)
  * `features`: List of feature tags (e.g., "No-Logging", "Malware Filter", "DNSSEC")
  * `ipv4`: List of primary and secondary IPv4 addresses
  * `ipv6`: List of primary and secondary IPv6 addresses
  * `latencyMs`: Optional measured round-trip time in milliseconds
  * `isCustom`: Boolean indicating user-created provider
* **`DpiBypassMode`** (`lib/domain/entities/dpi_bypass_mode.dart`):
  * `id`: Mode identifier
  * `name`: Human-readable name (e.g., "Standard Bypass", "YouTube Focus")
  * `description`: Purpose and strategy
  * `args`: Command-line flags passed to `goodbyedpi.exe`
* **`AppLogEntry`** (`lib/domain/entities/app_log_entry.dart`):
  * `timestamp`: DateTime
  * `level`: Log level (`info`, `warning`, `severe`)
  * `tag`: Subsystem tag
  * `message`: Log text

#### Interfaces
* **`INetworkService`**:
  * `Future<bool> isAdministrator()`
  * `Future<List<NetworkAdapter>> getAdapters()`
  * `Future<List<String>> getCurrentDns(String adapterName)`
  * `Future<void> setDns(String adapterName, List<String> ipv4, List<String> ipv6)`
  * `Future<void> restoreDns(String adapterName)`
  * `Future<void> flushDnsCache()`
  * `Future<int?> pingHost(String host, {Duration timeout})`
* **`IDpiService`**:
  * `bool get isRunning`
  * `Stream<bool> get runningStateStream`
  * `Stream<String> get processLogsStream`
  * `Future<bool> isExecutableAvailable()`
  * `Future<void> start(DpiBypassMode mode)`
  * `Future<void> stop()`
  * `void dispose()`
* **`IDnsProviderRepository`**:
  * `List<DnsProvider> getBuiltInProviders()`
  * `Future<List<DnsProvider>> getAllProviders()`
  * `Future<void> addCustomProvider(DnsProvider provider)`
  * `Future<void> deleteCustomProvider(String id)`

---

### 3.2 Data Layer (`lib/data/`)

* **`WindowsNetworkService`**:
  * Implements `INetworkService` on Windows using PowerShell and `ipconfig`.
  * Sanitizes inputs to prevent command injection.
  * Combines IPv4 and IPv6 arrays into a single `Set-DnsClientServerAddress -InterfaceAlias $safeName -ServerAddresses @($allIps)` call.
  * Executes `ipconfig /flushdns` and `Clear-DnsClientCache`.
  * Performs ICMP ping via `Test-Connection` or Raw Socket ping with timeout.
* **`MockNetworkService`**:
  * Implements `INetworkService` for non-Windows platforms (Linux, macOS) and automated tests.
  * Simulates network adapters, DNS changes, cache flushes, and ping latencies realistically without external process dependency.
* **`WindowsDpiService`**:
  * Locates `goodbyedpi.exe` in application directory or executable path.
  * Launches process with non-blocking stdout/stderr stream listeners forwarding to the app log.
  * Tracks PID and provides immediate exit code notification.
  * Registered as a `WidgetsBindingObserver` to terminate child processes when the Flutter application shuts down.
* **`MockDpiService`**:
  * Simulates DPI bypass execution for non-Windows and unit/widget test environments.
* **`DnsProviderRepositoryImpl`**:
  * In-memory repository with pre-configured verified resolvers: Cloudflare (1.1.1.1), Google Public DNS (8.8.8.8), Quad9 (9.9.9.9), AdGuard DNS (94.140.14.14), CleanBrowsing (185.228.168.9), DNS.SB (185.222.222.222), Mullvad (194.242.2.2), OpenDNS (208.67.222.222).
  * Persists custom user resolvers.

---

### 3.3 Presentation & State Layer (`lib/presentation/`)

* **`NavigationViewModel`**:
  * Manages active navigation destination index (0: Dashboard, 1: DNS Resolvers, 2: DPI Bypass Studio, 3: Diagnostics).
* **`NetworkDnsViewModel`**:
  * Manages adapter selection, active DNS retrieval, applying DNS, restoring DHCP, flushing cache, and ping latency benchmarking.
  * Separate loading flags: `isLoadingAdapters`, `isApplyingDns`, `isFlushingCache`, `isPinging`.
  * User feedback: Structured notification model (`type: success | error | info`, `message: String`).
* **`DpiViewModel`**:
  * Manages active mode selection, checking `goodbyedpi.exe` file presence, starting/stopping bypass, and forwarding output to diagnostics.
* **`DiagnosticsViewModel`**:
  * Maintains structured log entries in memory with filtering by severity and search term.
  * "Copy to clipboard" and "Clear" utilities.

---

## 4. UI/UX Specifications (Windows 11 Fluent Theme)

### 4.1 Shell Layout
* **App Bar**:
  * Logo & Title ("Butterfly Network Suite").
  * Administrator elevation chip (Green "Administrator" / Amber "Standard User - Some features require elevation").
  * Global actions: "Flush Cache" quick button, "Refresh Adapters", Theme toggle (System / Dark / Light).
* **Navigation Rail**:
  * Left sidebar with icons and labels:
    * `Dashboard` (`Icons.dashboard_rounded`)
    * `DNS Resolvers` (`Icons.dns_rounded`)
    * `DPI Bypass` (`Icons.shield_rounded`)
    * `Diagnostics` (`Icons.terminal_rounded`)

### 4.2 Screens
1. **Dashboard Screen**:
   * Top card: Active Adapter details (Interface Name, Status, Primary IPv4).
   * Current DNS status card: Large indicator showing active DNS addresses and badge (*DHCP Automatic* vs *Configured DNS*).
   * Quick Actions: "Reset to DHCP", "Flush DNS Cache", "Switch to Cloudflare (1.1.1.1)", "Switch to Google (8.8.8.8)".
   * DPI Bypass Quick Status card.
2. **DNS Resolvers Screen**:
   * Search input + Filter Chips (*All*, *Privacy & Security*, *High Speed / Gaming*, *Family Safe*, *Custom*).
   * Latency Benchmark Bar: "Run Speed Test" button that tests all DNS providers simultaneously.
   * Responsive Grid / List of Provider Cards:
     * Provider Name, Category badge, Latency pill (green <30ms, amber <80ms, red >80ms).
     * Feature tags (e.g. *No Logs*, *DNSSEC*, *Ad-Block*).
     * IPv4 & IPv6 addresses with copy-on-click.
     * Primary action: "Apply DNS" button with loading indicator.
   * Floating Action Button: "Add Custom DNS" opening a validated dialog.
3. **DPI Bypass Studio**:
   * Status Header: Running status (Green active banner with PID vs Gray inactive).
   * Binary Presence Card: Confirms `goodbyedpi.exe` presence; provides clear instructions if absent.
   * Preset Mode Cards: Grid of DPI modes with argument details.
   * Action Controls: Prominent Start / Stop button.
4. **Diagnostics & Logs Screen**:
   * Live console log viewer with syntax coloring based on log severity.
   * Filter controls: All, Info, Warning, Error.
   * Search bar.
   * "Copy All Logs" and "Clear Console" action buttons.

---

## 5. Testing & Verification Plan

1. **Unit Tests**:
   * `NetworkAdapter` and `DnsProvider` serialization and domain logic.
   * `INetworkService` operations (setting combined DNS, resetting, error handling).
   * `DnsProviderRepository` custom provider storage and retrieval.
   * `NetworkDnsViewModel` state transitions, adapter selection, and error handling.
   * `DpiViewModel` start/stop lifecycle and process exit handling.
2. **Widget Tests**:
   * App navigation rail renders properly and switches between pages.
   * Dashboard shows adapter details and DNS status.
   * DNS Resolvers screen displays providers, filters by category, and triggers apply action.
   * Diagnostics screen displays log entries.
3. **Static Analysis & Linting**:
   * Zero analysis issues (`flutter analyze`).
   * Adherence to project `rules.md` (lines <= 80 characters, descriptive names, `debugPrint` or structured logging).
