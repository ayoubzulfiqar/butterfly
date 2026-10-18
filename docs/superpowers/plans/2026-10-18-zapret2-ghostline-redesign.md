# zapret2 DPI Engine & Ghostline Feature Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade Butterfly with a dual-platform `zapret2` DPI bypass engine (Linux `nfqws2` + `nftables`, Windows `winws2` + `WinDivert`), driverless TLS ClientHello fragmentation, bulletproof DNS safety-net restoration, diagnostic Cloudflare Clean-IP scanner, and an overhaul to a silky-smooth dual-mode desktop UI (Simple Shield vs Full Studio).

**Architecture:** Model-View-ViewModel (MVVM) with provider-based dependency injection. Platform-adaptive service layer dispatching to native Linux Netlink/nftables and Windows WinDivert processes. Pure Dart local user-space TCP proxy for driverless SNI fragmentation. Hardware-accelerated 60/120fps physics animations (`AnimatedSize`, `TweenAnimationBuilder`, `CustomPainter`) eliminating layout jank.

**Tech Stack:** Flutter Desktop (Linux & Windows), Dart 3, `nftables` (Linux netlink/cli), WinDivert (Windows `winws2`), `http` package, `process_run`.

**Spec:** [docs/superpowers/specs/2026-10-18-zapret2-ghostline-redesign-design.md](file:///home/sensei/Projects/flutter/butterfly/docs/superpowers/specs/2026-10-18-zapret2-ghostline-redesign-design.md)

## Global Constraints
- Target Platforms: Linux (x86_64, Wayland/X11, GTK3) and Windows (x64, Windows 10/11).
- DPI Engine Binaries: `nfqws2` (Linux) and `winws2.exe` (Windows); legacy fallback `goodbyedpi.exe`.
- Linux Firewall Safety: `table inet butterfly_dpi` must use `queue num 510 bypass` to guarantee zero network disconnection if the engine terminates.
- Driverless Fallback: `TlsFragmenterService` must run in user-space without root or kernel driver dependencies.
- UI Performance: Zero layout jumping; all reflows must use `AnimatedSize` with `Curves.easeOutCubic`.

## Review Focus
1. **Linux elevation failure:** Verify `nfqws2` surfaces clear permission guidance if `pkexec` or root authorization is denied without hanging or crashing.
2. **WinDivert driver collision:** Verify `winws2.exe` handles active driver locks from third-party tools cleanly and offers fallback to GoodbyeDPI.
3. **TLS Fragmenter stream safety:** Verify non-TLS traffic or malformed handshakes pass through transparently without stalling or truncating TCP connections.
4. **Safety net state corruption:** Verify malformed, empty, or unreadable `state.json` snapshot files do not crash the app at startup.
5. **Animation smoothness:** Verify the rotating celestial ring and segmented pill slider render at 60/120fps without triggering RenderFlex overflows during window resizing.

---

### Task 1: zapret2 Domain Models & Strategy Catalog

**Files:**
- Create: `lib/src/features/dpi/domain/models/zapret2_strategy.dart`
- Create: `lib/src/features/dpi/domain/services/dpi_engine.dart`
- Modify: `lib/src/features/dpi/domain/models/dpi_status.dart`
- Test: `test/features/dpi/domain/zapret2_strategy_test.dart`

**Interfaces:**
- Produces:
  ```dart
  enum Zapret2Profile { light, medium, strong, extreme, custom }
  class Zapret2Strategy {
    final String id;
    final String name;
    final String description;
    final List<String> tcpArgs;
    final List<String> quicArgs;
  }
  abstract class DpiEngine {
    String get id;
    String get name;
    Future<bool> isAvailable();
    Future<Process> start(DpiConfig config);
    Future<void> stop();
    List<String> buildArgs(DpiConfig config);
  }
  ```

- [ ] **Step 1: Write the failing unit tests for zapret2 strategies and engine contracts**
- [ ] **Step 2: Run test to verify it fails (`flutter test test/features/dpi/domain/zapret2_strategy_test.dart`)**
- [ ] **Step 3: Implement `Zapret2Strategy`, `Zapret2Profile`, and `DpiEngine` interfaces**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit `git commit -m "feat(dpi): add zapret2 domain models, strategy catalog, and engine contracts"`**

---

### Task 2: Dual-Platform zapret2 Engines (Linux nfqws2 + Windows winws2)

**Files:**
- Create: `lib/src/features/dpi/data/services/zapret2_linux_engine.dart`
- Create: `lib/src/features/dpi/data/services/zapret2_windows_engine.dart`
- Create: `lib/src/features/dpi/data/services/goodbyedpi_engine.dart`
- Modify: `lib/src/features/dpi/data/services/dpi_service_impl.dart`
- Test: `test/features/dpi/data/zapret2_engines_test.dart`

**Interfaces:**
- Consumes: `DpiEngine`, `Zapret2Strategy`, `DpiConfig` from Task 1.
- Produces:
  ```dart
  class Zapret2LinuxEngine implements DpiEngine { ... }
  class Zapret2WindowsEngine implements DpiEngine { ... }
  class GoodbyeDpiEngine implements DpiEngine { ... }
  ```

- [ ] **Step 1: Write failing tests for Linux and Windows argument assembly and nftables rule formatting**
- [ ] **Step 2: Run test to verify it fails (`flutter test test/features/dpi/data/zapret2_engines_test.dart`)**
- [ ] **Step 3: Implement `Zapret2LinuxEngine` (with `queue num 510 bypass mark 0x10000`), `Zapret2WindowsEngine` (with `--wf-tcp-out` filters), and `GoodbyeDpiEngine`**
- [ ] **Step 4: Refactor `DpiServiceImpl` to support multi-engine selection and reactive process lifecycle tracking**
- [ ] **Step 5: Run tests to verify all pass**
- [ ] **Step 6: Commit `git commit -m "feat(dpi): implement Linux nfqws2 and Windows winws2 engines with nftables and WinDivert"`**

---

### Task 3: Driverless TLS ClientHello Fragmentation Engine (`tlsfrag`)

**Files:**
- Create: `lib/src/features/proxy/domain/services/tls_fragmenter.dart`
- Create: `lib/src/features/proxy/data/services/tls_fragmenter_service_impl.dart`
- Test: `test/features/proxy/tls_fragmenter_test.dart`

**Interfaces:**
- Produces:
  ```dart
  enum TlsFragMethod { tcp, record, both }
  abstract class TlsFragmenterService {
    bool get isRunning;
    int get port;
    Future<void> start({int port = 8085, TlsFragMethod method = TlsFragMethod.both, int chunks = 2});
    Future<void> stop();
  }
  ```

- [ ] **Step 1: Write failing tests for SNI detection, ClientHello range extraction, and payload fragmentation**
- [ ] **Step 2: Run test to verify it fails (`flutter test test/features/proxy/tls_fragmenter_test.dart`)**
- [ ] **Step 3: Implement `TlsFragmenterServiceImpl` pure Dart proxy server with `MethodTCP`, `MethodRecord`, and `MethodBoth`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit `git commit -m "feat(proxy): add driverless TLS ClientHello fragmentation engine"`**

---

### Task 4: Bulletproof Safety-Net DNS Restoration (`DnsSafetyNetService`)

**Files:**
- Create: `lib/src/features/dns/domain/services/dns_safety_net_service.dart`
- Create: `lib/src/features/dns/data/services/dns_safety_net_service_impl.dart`
- Modify: `lib/src/features/dns/data/services/dns_service_impl.dart`
- Test: `test/features/dns/dns_safety_net_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class DnsSnapshot {
    final String interfaceName;
    final bool isDhcp;
    final List<String> servers;
    final DateTime timestamp;
  }
  abstract class DnsSafetyNetService {
    Future<void> snapshotCurrentDns(String interfaceName);
    Future<bool> hasPendingRestore();
    Future<void> restoreOriginalDns();
    Future<void> clearSnapshot();
  }
  ```

- [ ] **Step 1: Write failing tests for snapshot serialization, file persistence, and automatic recovery on startup**
- [ ] **Step 2: Run test to verify it fails (`flutter test test/features/dns/dns_safety_net_test.dart`)**
- [ ] **Step 3: Implement `DnsSafetyNetServiceImpl` with JSON state storage and integration into `DnsServiceImpl`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit `git commit -m "feat(dns): implement bulletproof DNS safety-net snapshot and restoration service"`**

---

### Task 5: Diagnostic Cloudflare Clean-IP Scanner (`cfscan`)

**Files:**
- Create: `lib/src/features/tools/domain/services/cloudflare_scanner_service.dart`
- Create: `lib/src/features/tools/data/services/cloudflare_scanner_service_impl.dart`
- Modify: `lib/src/features/tools/presentation/viewmodels/tools_viewmodel.dart`
- Test: `test/features/tools/cloudflare_scanner_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class CloudflareCleanIp {
    final String ip;
    final int latencyMs;
    final double packetLoss;
    final bool isClean;
  }
  abstract class CloudflareScannerService {
    Stream<double> get progressStream;
    Future<List<CloudflareCleanIp>> scanCleanIps({int limit = 10});
  }
  ```

- [ ] **Step 1: Write failing tests for Anycast IP benchmarking, TTFB measurement, and clean ranking**
- [ ] **Step 2: Run test to verify it fails (`flutter test test/features/tools/cloudflare_scanner_test.dart`)**
- [ ] **Step 3: Implement `CloudflareScannerServiceImpl` probing `speed.cloudflare.com` and connect to `ToolsViewModel`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit `git commit -m "feat(tools): implement Cloudflare clean-IP diagnostic scanner"`**

---

### Task 6: Cyber-Minimal Design System & Interactive Neon Power Shield

**Files:**
- Create: `lib/src/core/theme/cyber_theme.dart`
- Create: `lib/src/core/presentation/widgets/neon_power_shield.dart`
- Create: `lib/src/core/presentation/widgets/protection_levels_bar.dart`
- Test: `test/core/presentation/neon_power_shield_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class CyberTheme {
    static const Color background = Color(0xFF0B0D13);
    static const Color surface = Color(0xFF141824);
    static const Color border = Color(0xFF1E2640);
    static const Color neonEmerald = Color(0xFF00FFA3);
    static const Color cyberCyan = Color(0xFF00D0FF);
    static const Color neonAmber = Color(0xFFFFB703);
    static const Color neonCoral = Color(0xFFFF4D6D);
  }
  class NeonPowerShield extends StatelessWidget { ... }
  class ProtectionLevelsBar extends StatelessWidget { ... }
  ```

- [ ] **Step 1: Write failing widget tests verifying NeonPowerShield states (off, busy, on, err) and ProtectionLevelsBar selection**
- [ ] **Step 2: Run test to verify it fails (`flutter test test/core/presentation/neon_power_shield_test.dart`)**
- [ ] **Step 3: Implement `CyberTheme`, `NeonPowerShield` with rotating celestial ring CustomPainter, and animated `ProtectionLevelsBar`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit `git commit -m "feat(ui): create CyberTheme, interactive NeonPowerShield, and ProtectionLevelsBar"`**

---

### Task 7: Silky-Smooth Dual-Mode Shell & Simple Shield Screen

**Files:**
- Create: `lib/src/features/shell/presentation/screens/simple_shield_screen.dart`
- Modify: `lib/src/features/shell/presentation/screens/main_shell_screen.dart`
- Modify: `lib/src/features/shell/presentation/viewmodels/navigation_viewmodel.dart`
- Test: `test/features/shell/presentation/simple_shield_screen_test.dart`

**Interfaces:**
- Consumes: `NeonPowerShield`, `ProtectionLevelsBar`, `DpiViewModel`, `DnsViewModel`.
- Produces:
  - Toggle between `AppViewMode.simple` and `AppViewMode.studio`.
  - Smooth layout resizing via `AnimatedSize` and `AnimatedSwitcher`.

- [ ] **Step 1: Write failing widget test for Simple Shield screen rendering, mode toggling, and telemetry HUD**
- [ ] **Step 2: Run test to verify it fails (`flutter test test/features/shell/presentation/simple_shield_screen_test.dart`)**
- [ ] **Step 3: Implement `SimpleShieldScreen` and update `MainShellScreen` to support dual-mode switching**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit `git commit -m "feat(shell): implement SimpleShieldScreen and dual-mode shell transitions"`**

---

### Task 8: Revamped Full Studio Mode & DPI Bypass Studio Page

**Files:**
- Modify: `lib/src/features/dpi/presentation/screens/dpi_bypass_page.dart`
- Modify: `lib/src/features/dpi/presentation/viewmodels/dpi_viewmodel.dart`
- Create: `lib/src/features/proxy/presentation/screens/proxy_fragmentation_page.dart`
- Modify: `lib/src/features/tools/presentation/screens/tools_page.dart`
- Test: `test/features/dpi/presentation/dpi_bypass_page_test.dart`

**Interfaces:**
- Provides engine selection chips (`zapret2` vs `goodbyedpi`), strategy selection cards, live CLI argument preview, TLS fragmentation settings, and Cloudflare clean-IP scan card.

- [ ] **Step 1: Write failing widget tests for DpiBypassPage engine switching and CLI preview**
- [ ] **Step 2: Run test to verify it fails (`flutter test test/features/dpi/presentation/dpi_bypass_page_test.dart`)**
- [ ] **Step 3: Refactor `DpiBypassPage`, create `ProxyFragmentationPage`, and add `CloudflareScannerCard` to `ToolsPage`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit `git commit -m "feat(studio): revamp DPI Studio with zapret2 strategies, TLS frag page, and CF scanner"`**

---

### Task 9: End-to-End Verification, Static Analysis & Native Linux Binary Smoke Test

**Files:**
- Verify: Full test suite (`flutter test`)
- Verify: Static analysis (`flutter analyze`)
- Verify: Native Linux binary compilation (`flutter build linux --debug`)

- [ ] **Step 1: Run all unit and widget tests across the entire test suite**
- [ ] **Step 2: Run `flutter analyze` and resolve all mechanical lints or warnings**
- [ ] **Step 3: Build native Linux binary to guarantee Wayland/X11 compilation integrity**
- [ ] **Step 4: Commit `git commit -m "chore: verify test suite, zero lints, and clean Linux build"`**
