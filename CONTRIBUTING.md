# Contributing to Butterfly

Thank you for your interest in contributing to **Butterfly**! Butterfly is an enterprise-grade, cross-platform desktop suite for resilient DNS resolution, Deep Packet Inspection (DPI) circumvention (`zapret2`), driverless TLS ClientHello fragmentation, and network diagnostics.

We welcome contributions from engineers, researchers, and designers worldwide. To maintain software reliability and security, please review the following guidelines before submitting issues or pull requests.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features & Enhancements](#suggesting-features--enhancements)
  - [Submitting Code Changes](#submitting-code-changes)
- [Development Setup](#development-setup)
  - [Prerequisites](#prerequisites)
  - [Linux Workstation Setup](#linux-workstation-setup)
  - [Windows Workstation Setup](#windows-workstation-setup)
  - [Cloning & Building](#cloning--building)
- [Architectural Principles](#architectural-principles)
  - [Clean Architecture & MVVM](#clean-architecture--mvvm)
  - [Platform-Adaptive Service Isolation](#platform-adaptive-service-isolation)
  - [Defensive Network & Elevation Safety](#defensive-network--elevation-safety)
- [Engineering Standards](#engineering-standards)
  - [Commit Message Format](#commit-message-format)
  - [Test-Driven Development (TDD)](#test-driven-development-tdd)
  - [Static Analysis & Zero-Lint Rule](#static-analysis--zero-lint-rule)
- [Pull Request Process](#pull-request-process)
- [Getting Help](#getting-help)

---

## Code of Conduct

All contributors and maintainers are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md). Please report any unacceptable behavior to [security@butterfly-project.org](mailto:security@butterfly-project.org).

---

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check existing [GitHub Issues](https://github.com/DnsChanger/dnsChanger-desktop/issues) to avoid duplicates.

When filing a bug via our [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.yml), include:
- **Operating System & Architecture**: (e.g., Linux Fedora 41 x86_64, Windows 11 23H2 x64).
- **Network Interface**: (e.g., Wi-Fi, Ethernet, systemd-resolved / nmcli / netsh).
- **Exact Reproduction Steps**: Step-by-step instructions.
- **Expected vs. Actual Behavior**.
- **Relevant Logs**: Non-sensitive console logs or diagnostic outputs (`lib/core/utils/logger.dart`).

> [!CAUTION]
> **Do not report security vulnerabilities publicly.** Follow our [Security Policy](SECURITY.md) to submit disclosures responsibly.

### Suggesting Features & Enhancements

We welcome proposals for new DNS providers, DPI strategies, diagnostic probes, and accessibility improvements. Please use our [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.yml) to articulate:
1. The problem or censorship mechanism being addressed.
2. The proposed technical design and platform implications.
3. Fallback behavior for unsupported platforms.

### Submitting Code Changes

1. Fork the repository and create a descriptive branch:
   ```bash
   git checkout -b feat/zapret2-http3-bypass
   # or
   git checkout -b fix/linux-nftables-parsing
   ```
2. Write unit/widget tests verifying your change.
3. Ensure all tests pass (`flutter test`) and static analysis reports 0 issues (`flutter analyze`).
4. Push your branch and open a Pull Request targeting `main`.

---

## Development Setup

### Prerequisites

- **Flutter SDK**: 3.24.0 or newer (Channel `stable`)
- **Dart SDK**: 3.5.0 or newer
- **Git**: 2.30+

### Linux Workstation Setup

On Debian/Ubuntu-based distributions:
```bash
sudo apt-get update
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev nftables libnetfilter-queue-dev
```

On Fedora/RHEL-based distributions:
```bash
sudo dnf install -y \
  clang cmake ninja-build pkgconfig \
  gtk3-devel xz-devel nftables libnetfilter_queue-devel
```

### Windows Workstation Setup

- **Visual Studio 2022**: Community edition with "Desktop development with C++" workload installed.
- **PowerShell**: 5.1+ or PowerShell 7+.
- **Administrator Elevation**: Required to test `netsh` adapter mutations and `WinDivert` packet filtering.

### Android Workstation Setup

- **Java Development Kit**: OpenJDK 17 or higher (`JAVA_HOME` configured).
- **Android SDK**: API level 34/35 (`compileSdk 35`, `targetSdk 34`, `minSdk 24`).
- **Android Studio** or Android command-line tools with platform-tools and Gradle installed.

### Cloning & Building

```bash
# 1. Clone your fork
git clone https://github.com/<your-username>/butterfly.git
cd butterfly

# 2. Install dependencies
flutter pub get

# 3. Run unit and widget tests (111/111 passing)
flutter test

# 4. Verify static analysis (0 issues)
flutter analyze

# 5. Build native binaries & packages
# Linux desktop:
flutter build linux --debug

# Windows desktop:
flutter build windows --debug

# Android debug APK:
flutter build apk --debug

# Android Kotlin compilation:
cd android && ./gradlew compileDebugKotlin && cd ..
```

---

## Architectural Principles

### Clean Architecture & MVVM

Butterfly strictly enforces separation of concerns across three layers:
```
lib/
├── core/                  # Utilities, logging, themes (CyberTheme), constants
├── domain/                # Enterprise entities, repository interfaces, engine contracts
│   ├── entities/          # Pure immutable data models (DnsProvider, Zapret2Strategy, etc.)
│   ├── repositories/      # Abstract data access interfaces
│   └── services/          # Pure domain contracts (IDpiService, INetworkService, etc.)
├── data/                  # Service implementations and platform bindings
│   ├── repositories/      # DnsProviderRepositoryImpl, remote sync, fallbacks
│   └── services/          # Zapret2LinuxEngine, Zapret2WindowsEngine, TlsFragmenterServiceImpl, etc.
└── presentation/          # Flutter UI layer
    ├── viewmodels/        # ChangeNotifier ViewModels (NetworkDnsViewModel, DpiViewModel, etc.)
    ├── views/             # Screens (MainShellScreen, SimpleShieldScreen) and pages
    └── widgets/           # Reusable UI components (NeonPowerShield, FluentCard, StatusBadge)
```

### Platform-Adaptive Service Isolation

Platform-specific logic must be isolated in the `data/services/` layer and resolved via `PlatformServiceFactory`. UI code must **never** call `Platform.isLinux`, `Platform.isWindows`, or `Platform.isAndroid` directly to execute raw commands or channel logic.

### Defensive Network & Elevation Safety

1. **No Destructive Disconnects**:
   - On Linux, all `nftables` queue rules must use `queue flags bypass to <queue_num>` so traffic continues flowing uninterrupted if `nfqws2` crashes or stops.
2. **Safe Elevation**:
   - Privilege escalation must use `pkexec` on Linux with explicit arguments.
   - Never pass unsanitized user inputs or shell concatenations into `Process.start` or `Process.run`. All string inputs (interface names, DNS IP addresses) must pass strict regex validation.
3. **Bulletproof Safety Net**:
   - Every desktop DNS mutation must snapshot existing adapter state to `state.json` via `IDnsSafetyNetService`. If the app crashes, the snapshot is automatically recovered and applied on next launch.
4. **Rootless Mobile Architecture**:
   - Android functionality must never require root/su or busybox binaries. Use standard Android `VpnService` with explicit user intent consent (`prepare`), forward DNS queries via protected UDP sockets, and preserve line-rate non-DNS app traffic.

---

## Engineering Standards

### Commit Message Format

We adhere to [Conventional Commits 1.0.0](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short description in present imperative tense>

[optional body explaining motivation and technical approach]

[optional footer referencing issue numbers: e.g., Fixes #42]
```

**Allowed Types:**
- `feat`: A new user-facing feature or domain capability.
- `fix`: A bug fix or error remediation.
- `docs`: Documentation updates, specs, or inline documentation.
- `test`: Adding missing tests or refactoring test suites.
- `refactor`: Code changes that neither fix a bug nor add a feature.
- `perf`: Code changes that improve runtime performance or frame rate.
- `chore`: Tooling, build scripts, dependency updates, or git configuration.

### Test-Driven Development (TDD)

Every new feature or bug fix must include corresponding tests:
- **Unit Tests** (`test/unit/`): Verify core domain models, argument builders, parsers, and data services.
- **Widget Tests** (`test/widget/`): Verify UI state rendering, user interaction, theme propagation, and responsiveness.
- All tests must pass cleanly before any code review:
  ```bash
  flutter test
  ```

### Static Analysis & Zero-Lint Rule

We enforce strict Dart analysis rules defined in [`analysis_options.yaml`](analysis_options.yaml).
- Pull requests with compiler warnings, unused imports, or lint violations will not be merged.
- Run static analysis locally:
  ```bash
  flutter analyze
  ```
  *(Expected output: `No issues found!`)*

---

## Pull Request Process

1. **Keep PRs Focused**: One feature, refactor, or bugfix per PR. Avoid massive kitchen-sink pull requests.
2. **Fill Out the PR Template**: Complete all sections of the [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md), including testing evidence and platform verification notes.
3. **Verify All Checks**:
   - `flutter analyze` passes with 0 issues.
   - `flutter test` passes 100%.
   - Native build succeeds on at least one target platform.
4. **Code Review**: A maintainer will review your pull request for architectural alignment, security considerations, and code clarity. Address feedback respectfully and update your branch.
5. **Merge**: Once approved, your PR will be squash-merged with a conventional commit message.

---

## Getting Help

- Join discussions and questions via [GitHub Issues](https://github.com/DnsChanger/dnsChanger-desktop/issues).
- Security queries: [security@butterfly-project.org](mailto:security@butterfly-project.org).

Thank you for helping keep Butterfly the most resilient, private, and dependable DNS and DPI bypass suite!
