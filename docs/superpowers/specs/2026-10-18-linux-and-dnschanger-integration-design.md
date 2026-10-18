# Multi-Platform Linux Support & dnsChanger-desktop Integration Specification

**Date:** 2026-10-18  
**Status:** Approved  
**Author:** Senior Flutter Engineer & System Architect  
**Target Platforms:** Windows 10/11 (x64), Linux Desktop (Ubuntu, Debian, Fedora, Arch GTK x64)

---

## 1. Executive Summary

This document specifies the architectural expansion of the **Butterfly** desktop application to provide native **Linux desktop support** and integrate the full feature set from [`dnsChanger-desktop`](https://github.com/DnsChanger/dnsChanger-desktop):
1. **Linux Desktop Runner & Engine:** Enabling native Flutter Linux compilation with a robust, enterprise-grade `LinuxNetworkService` leveraging `systemd-resolved` (`resolvectl`) and NetworkManager (`nmcli`), avoiding naive destructive `/etc/resolv.conf` rewrites.
2. **Expanded DNS Resolver Catalog:** Integrating 25+ curated international and regional anti-sanction/gaming/web resolvers (Shecan, Electro Team, Radar Game, Zeus DNS, Asiatech, FiveM, AdGuard, ControlD, dns0.eu, etc.) with remote catalog sync from GitHub (`servers_DB.json`) and local JSON caching.
3. **Censorship & Target Benchmark Engine:** Implementing an active censorship diagnostic engine that resolves designated domains (ChatGPT, Claude, YouTube, Google, Twitter/X, GitHub, Discord) directly against candidate nameservers and validates transport reachability via HTTP probes.
4. **Desktop Utility Suite (Tools Studio):** Introducing a multi-tab system utility workspace featuring:
   - **Public IP & Telemetry** (Public IP, ASN, ISP name, location, coordinates, timezone).
   - **Network Adapter Switcher** (Hardware interface inspection, enable/disable toggling, and active DNS target selection).
   - **Scheduled Shutdown** (OS-level countdown shutdown timers and cancellation for both Windows and Linux).

---

## 2. Architecture & Domain Contracts

The application maintains strict Clean Architecture with domain contracts isolating UI and ViewModels from platform-specific APIs.

```
lib/
├── domain/
│   ├── entities/
│   │   ├── network_adapter.dart          # Adapter metadata & DHCP detection
│   │   ├── dns_provider.dart             # Provider definition, tags, and ratings
│   │   ├── dpi_bypass_mode.dart          # GoodbyeDPI presets
│   │   ├── app_log_entry.dart            # Diagnostic logging
│   │   ├── benchmark_target.dart         # (New) Target web services for censorship benchmark
│   │   ├── public_ip_info.dart           # (New) Public IP, ASN, GeoLocation telemetry
│   │   └── scheduled_shutdown_state.dart # (New) Active shutdown tracking entity
│   └── services/
│       ├── i_network_service.dart        # Core DNS & adapter contract
│       ├── i_dpi_service.dart            # DPI bypass service contract
│       ├── i_dns_provider_repository.dart# Provider catalog contract
│       ├── i_dns_benchmark_service.dart  # (New) Target-based censorship benchmark
│       └── i_system_tools_service.dart   # (New) IP lookup, adapter toggles, shutdown
├── data/
│   ├── services/
│   │   ├── platform_service_factory.dart # (New) Platform detector & service resolver
│   │   ├── windows_network_service.dart  # PowerShell/netsh Windows engine
│   │   ├── linux_network_service.dart    # (New) resolvectl/nmcli Linux engine
│   │   ├── windows_dpi_service.dart      # GoodbyeDPI process manager
│   │   ├── linux_dpi_service.dart        # (New) Informational DPI engine for Linux
│   │   ├── dns_benchmark_service_impl.dart# (New) UDP port 53 lookup + HTTP probe
│   │   ├── system_tools_service_impl.dart# (New) Cross-platform tool executor
│   │   ├── mock_network_service.dart     # Test double
│   │   └── mock_dpi_service.dart         # Test double
│   └── repositories/
│       └── dns_provider_repository_impl.dart # 25+ resolvers + remote sync + JSON storage
└── presentation/
    ├── viewmodels/
    │   ├── navigation_viewmodel.dart     # Active workspace navigation
    │   ├── network_dns_viewmodel.dart    # DNS application and monitoring
    │   ├── dpi_viewmodel.dart            # DPI bypass controls
    │   ├── diagnostics_viewmodel.dart    # Live logging stream
    │   └── tools_viewmodel.dart          # (New) IP, Adapter switcher, Shutdown state
    ├── views/
    │   ├── main_shell_screen.dart        # 5-item NavigationRail with IndexedStack
    │   └── pages/
    │       ├── dashboard_page.dart       # Telemetry and quick actions
    │       ├── dns_resolvers_page.dart   # Searchable catalog & target benchmark
    │       ├── dpi_bypass_page.dart      # Preset & custom DPI controls
    │       ├── tools_page.dart           # (New) Public IP, Adapter Switcher, Shutdown
    │       └── diagnostics_page.dart     # Streaming activity console
    └── widgets/
        ├── fluent_card.dart
        ├── status_badge.dart
        ├── elevation_banner.dart
        ├── custom_dns_dialog.dart
        ├── my_ip_card.dart               # (New) Public IP & ISP widget
        ├── adapter_switcher_card.dart    # (New) Hardware toggles widget
        └── scheduled_shutdown_card.dart  # (New) Shutdown presets & countdown widget
```

---

## 3. Platform Subsystem Specifications

### 3.1 Linux Platform Enablement
- Run `flutter create --platforms=linux .` to scaffold standard GTK C++ host project files.
- Integrate Linux window styling in `linux/my_application.cc` with standard window defaults (min size 960x640, title "Butterfly - Enterprise DNS & Network Suite").
- Ensure Linux compilation succeeds via `flutter build linux --debug` or `flutter analyze`.

### 3.2 Linux Network Engine (`LinuxNetworkService`)
1. **Interface Discovery:**
   - Execute `ip -j link` and `ip -j addr` to parse interface names, state (`UP`/`DOWN`), MAC addresses, and active IP allocations in structured JSON.
   - Execute `resolvectl dns` to parse assigned DNS servers per interface link.
2. **DNS Assignment:**
   - Execute `resolvectl dns <interface> <ip1> <ip2> ...`.
   - If user is non-root and `systemd-resolved` requires authentication, wrap command in `pkexec` or prompt for elevated authorization.
   - Enforce regex validation on interface name `^[a-zA-Z0-9_\-\.:]+$` and `InternetAddress.tryParse` on IP addresses to prevent shell escape bugs.
3. **Reset to Automatic (DHCP):**
   - Execute `resolvectl revert <interface>` (or `resolvectl dns <interface> ""`).
4. **Cache Flush:**
   - Execute `resolvectl flush-caches` (falling back to `systemd-resolve --flush-caches`).

### 3.3 Target Censorship Benchmark Engine (`IDnsBenchmarkService`)
- Replaces raw ICMP ping with application-level censorship detection:
  1. Resolves a target host (e.g. `chatgpt.com`, `google.com`, `x.com`) directly against the specified DNS server IP using UDP port 53.
  2. Initiates a lightweight HTTP/HTTPS connection to the resolved IP with `Host: <hostname>`.
  3. Returns a `DnsBenchmarkResult`:
     - `status`: `reachable` (HTTP 200–399), `blocked` (HTTP 403 Forbidden / DPI packet drop), `error` (5xx), or `failed`.
     - `latencyMs`: DNS resolution duration + HTTP connect duration.
     - `resolvedIp`: IP returned by the nameserver.

### 3.4 System Tools Service (`ISystemToolsService`)
1. **Public IP & Telemetry:**
   - Performs a GET request against `https://ip.wtf/` (with fallback to `https://api.ipify.org?format=json`).
   - Parses public IPv4/IPv6, ASN number, organization name, city, country, latitude, longitude, and timezone.
2. **Network Adapter Control:**
   - Toggles hardware interfaces:
     - Windows: `netsh interface set interface name="<adapter>" admin=ENABLED/DISABLED`.
     - Linux: `nmcli dev disconnect <adapter>` / `nmcli dev connect <adapter>` or `ip link set dev <adapter> up/down`.
3. **Scheduled Shutdown:**
   - Windows: `shutdown /s /t <seconds> /c "Scheduled shutdown from Butterfly"`.
   - Windows Cancel: `shutdown /a`.
   - Linux: `shutdown -h +<minutes>`.
   - Linux Cancel: `shutdown -c`.

---

## 4. UI/UX Specification

### 4.1 Navigation & Shell
- `MainShellScreen` navigation rail expands to 5 primary destinations:
  1. `Dashboard` (`Icons.dashboard_rounded`)
  2. `DNS Resolvers` (`Icons.dns_rounded`)
  3. `DPI Bypass` (`Icons.security_rounded`)
  4. `Tools` (`Icons.build_circle_rounded`)
  5. `Diagnostics` (`Icons.terminal_rounded`)
- Retains `IndexedStack` to preserve state across page transitions without widget re-instantiation.

### 4.2 Tools Page
- Segmented sub-views or responsive Fluent card grid:
  - **Public IP & ISP Card:** Displays live public IP with a copy button, geographic map pin, ISP tag, and ASN details.
  - **Adapter Switcher Card:** Lists detected physical and virtual adapters with interactive on/off toggles and an option to set the active DNS target.
  - **Scheduled Shutdown Card:** Quick time chips (`+15m`, `+30m`, `+1h`, `+2h`, `+3h`), custom date/time inputs, active countdown display, and cancellation button.

---

## 5. Testing & Verification Plan

1. **Unit Tests:**
   - `test/unit/linux_network_service_test.dart`: Command generation, interface parsing, IP validation, and safe shell execution.
   - `test/unit/dns_benchmark_service_test.dart`: Target parsing, DNS UDP resolution parsing, HTTP censorship classification.
   - `test/unit/system_tools_service_test.dart`: Shutdown command construction (Windows vs. Linux), cancellation syntax, IP telemetry parsing.
   - `test/unit/dns_provider_repository_test.dart`: Verify catalog contains all 25+ resolvers and handles remote sync fallback.
2. **Widget Tests:**
   - `test/widget/main_shell_test.dart`: Verify 5 navigation rail items and switching between all pages.
   - `test/widget/tools_page_test.dart`: Verify My IP loading/display, adapter toggles, and scheduled shutdown controls.
3. **Platform Verification:**
   - `flutter analyze` with 0 issues.
   - `flutter test` passing all test suites.
   - `flutter build linux --debug` (or compilation check) verifying valid Linux host configuration.
