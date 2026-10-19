# Butterfly

<div align="center">

![Butterfly Banner](https://raw.githubusercontent.com/DnsChanger/dnsChanger-desktop/main/assets/banner.png)

### Enterprise DNS Management & Advanced DPI Bypass Suite for Linux & Windows

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.24%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-lightgrey?logo=linux&logoColor=white)](docs/ARCHITECTURE.md)
[![Tests](https://img.shields.io/badge/Tests-90%2F90%20Passing-brightgreen.svg)](test/)
[![Analysis](https://img.shields.io/badge/Static%20Analysis-0%20Issues-brightgreen.svg)](analysis_options.yaml)
[![Code of Conduct](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

</div>

---

## Overview

**Butterfly** is an enterprise-grade desktop suite engineered to combat internet censorship, DNS tampering, and deep packet inspection (DPI). Built with Flutter Desktop and modern systems networking, Butterfly delivers low-latency DNS routing, fail-open kernel packet desynchronization (`zapret2`), driverless TLS ClientHello fragmentation, and automated crash-proof network restoration.

Whether you need a one-click shield to browse freely or an advanced networking laboratory to analyze and circumvent censorship middleboxes, Butterfly provides a silky-smooth, hardware-accelerated experience.

---

## Key Features

### 🛡️ Dual-Mode Desktop Experience
- **Simple Shield Mode**: An intuitive, cyber-minimalist HUD centered around the interactive `NeonPowerShield`. Features a 60/120fps rotating celestial ring, reactive hover glow, real-time security score telemetry, and one-click protection toggling.
- **Full Studio Mode**: A comprehensive 6-workspace desktop studio (*Dashboard, DNS Resolvers, DPI Bypass, Proxy & TLS Frag, Tools, Diagnostics*) with responsive layout scaling and state preservation across transitions.

### 🌐 Curated DNS Resolvers Catalog & Custom Overrides
- **28+ Curated Resolvers**: Instant access to global resolvers categorized by **Privacy** (*Cloudflare, Quad9, Mullvad*), **Security** (*CleanBrowsing, AdGuard*), **Gaming** (*Level3, OpenDNS*), and **Anti-Sanction / Censorship Bypass** (*Shecan, Electro, Radar*).
- **Remote Catalog Synchronization**: Background resolver catalog updates with offline cache fallback.
- **Custom Resolvers**: Create, test, and save custom IPv4/IPv6 DNS configurations.

### ⚡ `zapret2` DPI Bypass Engine
- **Linux (`nfqws2` + `nftables`)**: Hardware-accelerated Netfilter queue redirection (`NFQUEUE 510`) with guaranteed `queue flags bypass` fail-open rules to ensure zero network disconnection if the daemon terminates.
- **Windows (`winws2` + `WinDivert`)**: Kernel-level packet filter interception with automated orphan service cleanup preventing driver collision errors.
- **5 Standard Ghostline Strategies**: Includes `z-split` (TCP segment slicing), `z-disorder` (out-of-order delivery), `z-fake` (fake packet injection), `z-fake-ttl` (distance-calibrated TTL spoofing), and `z-custom` (CLI flag preview).
- **QUIC / UDP 443 Support**: Full toggleable evasion for HTTP/3 traffic.

### 🔀 Driverless TLS ClientHello Fragmentation Proxy
- **Zero Kernel Drivers / Zero Root**: Operates as a pure-Dart userspace HTTP CONNECT proxy on `127.0.0.1:8085`.
- **Pure-Dart SNI Parser**: Slices TLS ClientHello packets precisely across Server Name Indication boundaries.
- **Multiple Fragmentation Modes**: Supports TCP payload segmentation (`TlsFragMethod.tcp`), RFC 8446 TLS record wrapping (`TlsFragMethod.record`), and combined hybrid fragmentation.

### 🦺 Bulletproof DNS Safety Net
- **Persistent State File (`state.json`)**: Pre-flight snapshotting of network interface settings before any DNS mutation.
- **Ungraceful Crash Recovery**: Automatically discovers orphaned snapshots on startup, recovering original static or DHCP network settings if the system halted or crashed unexpectedly.
- **Live HUD Indicator**: Real-time arming badge reflecting network safety status.

### 📡 Cloudflare Anycast Clean-IP Scanner
- **Edge Latency Probing**: Concurrently scans Anycast IP ranges to identify unblocked edge nodes with the lowest TTFB (Time-To-First-Byte) latency in ~2 seconds.
- **Instant Override**: Apply any discovered clean IP directly as your active network adapter's DNS resolver with a single click.

### 🎯 Active Censorship Target Benchmark Engine
- **Direct RFC 1035 UDP Probing**: Probes DNS servers without OS cache interference.
- **HTTP / SNI Blocking Detection**: Sends simulated HTTP/HTTPS probes with host headers to evaluate domain reachability and classify DPI packet drops or HTTP 403 blocks.

### 🛠️ System Tools & Diagnostic Telemetry
- **Public IP & ISP Discovery**: Fast Anycast IP lookup with ASN, city, and provider telemetry.
- **Adapter Control**: Toggle physical and virtual network interfaces directly from the desktop UI.
- **Scheduled System Shutdown**: Cancelable system shutdown timers for Windows and Linux.
- **Live Diagnostics Console**: Real-time structured log streaming with search, filtering, and copy-to-clipboard capabilities.

---

## Architecture

Butterfly is engineered with **Clean Architecture** and **Model-View-ViewModel (MVVM)**, completely decoupling platform system calls from the presentation layer:

```
lib/
├── core/                  # Utilities, logging, Obsidian CyberTheme, constants
├── domain/                # Enterprise entities, repository interfaces, engine contracts
│   ├── entities/          # Pure immutable data models (DnsProvider, Zapret2Strategy, etc.)
│   ├── repositories/      # Abstract data access contracts
│   └── services/          # Domain service interfaces (IDpiService, INetworkService, etc.)
├── data/                  # Service implementations and platform bindings
│   ├── repositories/      # DnsProviderRepositoryImpl, remote sync, fallbacks
│   └── services/          # Zapret2LinuxEngine, Zapret2WindowsEngine, TlsFragmenterServiceImpl, etc.
└── presentation/          # Flutter UI layer
    ├── viewmodels/        # ViewModels (NetworkDnsViewModel, DpiViewModel, ToolsViewModel, etc.)
    ├── views/             # Screens (MainShellScreen, SimpleShieldScreen) and workspaces
    └── widgets/           # Atomic components (NeonPowerShield, FluentCard, StatusBadge)
```

For complete architectural specifications, threading models, and sequence diagrams, refer to [**docs/ARCHITECTURE.md**](docs/ARCHITECTURE.md).

---

## Platform Support & Prerequisites

| Feature | Linux | Windows |
| :--- | :---: | :---: |
| **DNS Management** | `resolvectl` / `nmcli` | `netsh` / `PowerShell` |
| **DNS Safety Net** | :white_check_mark: | :white_check_mark: |
| **zapret2 Engine** | `nfqws2` + `nftables` | `winws2.exe` + `WinDivert` |
| **Driverless TLS Proxy** | :white_check_mark: (:8085) | :white_check_mark: (:8085) |
| **Clean-IP Scanner** | :white_check_mark: | :white_check_mark: |
| **Censorship Benchmark** | :white_check_mark: | :white_check_mark: |
| **System Tools Studio** | :white_check_mark: | :white_check_mark: |

### Build Requirements

- **Flutter SDK**: 3.24.0 or higher (Channel `stable`)
- **Dart SDK**: 3.5.0 or higher

#### Linux Workstations
- Clang, CMake, Ninja, GTK 3, and Netfilter development libraries:
  ```bash
  # Debian / Ubuntu:
  sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev nftables libnetfilter-queue-dev

  # Fedora / RHEL:
  sudo dnf install -y clang cmake ninja-build pkgconfig gtk3-devel xz-devel nftables libnetfilter_queue-devel
  ```

#### Windows Workstations
- Visual Studio 2022 with **"Desktop development with C++"** workload.
- PowerShell 5.1+ or PowerShell 7+.

---

## Quickstart & Build Instructions

```bash
# 1. Clone the repository
git clone https://github.com/DnsChanger/dnsChanger-desktop.git
cd dnsChanger-desktop

# 2. Fetch dependencies
flutter pub get

# 3. Run the automated test suite (90/90 passing)
flutter test

# 4. Verify static analysis (0 issues)
flutter analyze

# 5. Build native application
# On Linux:
flutter build linux --debug

# On Windows:
flutter build windows --debug

# 6. Run the application
flutter run
```

---

## Documentation Index

Explore our in-depth technical documentation:

- 🏛️ [**System Architecture Specification**](docs/ARCHITECTURE.md) — Architectural patterns, process isolation, Netfilter queueing, and threading models.
- ⚡ [**DPI Bypass Engines Guide**](docs/DPI_BYPASS_ENGINES.md) — Deep dive into `zapret2` strategies, packet desynchronization, and pure-Dart SNI fragmentation.
- 🦺 [**DNS Safety Net Specification**](docs/SAFETY_NET.md) — Crash recovery protocol, state schema, and atomic file persistence.
- 🤝 [**Contributing Guidelines**](CONTRIBUTING.md) — Git workflow, TDD rules, code conventions, and pull request requirements.
- 🛡️ [**Security Policy**](SECURITY.md) — Vulnerability disclosure procedure, response SLA, and threat model.
- 📜 [**Code of Conduct**](CODE_OF_CONDUCT.md) — Contributor Covenant v2.1 community standards.

---

## Security & Elevation Model

Butterfly requires elevated privileges only for host network adapter mutations and kernel packet queue bindings:
- **Linux**: Interacts through `resolvectl` and `pkexec nft` with explicit argument passing. Shell string injection is strictly mitigated via argument arrays and regex whitelisting.
- **Windows**: Prompts for UAC elevation when executing adapter DNS changes via `netsh` and initializing the `WinDivert` driver service.
- **Driverless Fallback**: The **Proxy & TLS Frag** workspace operates purely in user-space, requiring no root or administrator permissions.

To report security concerns confidentially, please refer to [**SECURITY.md**](SECURITY.md).

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.  
See the [**LICENSE**](LICENSE) file for complete terms and conditions.

Copyright &copy; 2026 Butterfly Project Contributors.
