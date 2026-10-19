## Description

<!-- Provide a clear and concise summary of the changes introduced in this Pull Request. Explain why this change is necessary and what architectural components it touches. -->

## Type of Change

- [ ] 🚀 `feat`: New feature, strategy, or capability
- [ ] 🐛 `fix`: Bug fix or error remediation
- [ ] 🏎️ `perf`: Performance optimization or frame-rate improvement
- [ ] 🔄 `refactor`: Structural refactoring with no behavior change
- [ ] 📝 `docs`: Documentation, architecture guide, or specification update
- [ ] 🧪 `test`: Unit, widget, or integration tests
- [ ] 🔧 `chore`: Tooling, build config, or dependency updates

## Related Issues

<!-- Reference related issues: e.g. Fixes #123, Closes #456 -->
Fixes #

## Platform & Component Scope

- [ ] **Linux Desktop** (`systemd-resolved` / `nmcli` / `nftables` / `nfqws2`)
- [ ] **Windows Desktop** (`netsh` / `PowerShell` / `WinDivert` / `winws2`)
- [ ] **TLS Fragmentation Proxy** (Userspace HTTP CONNECT, port 8085)
- [ ] **DNS Safety Net** (`state.json` persistence & crash recovery)
- [ ] **Cloudflare Clean-IP Scanner** (Anycast TTFB latency probing)
- [ ] **UI / UX** (Obsidian `CyberTheme`, `NeonPowerShield`, Dual-Mode Shell)

## Verification & Testing Evidence

<!-- All PRs must provide proof of passing automated tests and static analysis. -->

```bash
# 1. Automated test suite output:
flutter test

# 2. Static analysis output:
flutter analyze
```

- [ ] `flutter test` passes with 100% success rate.
- [ ] `flutter analyze` reports `No issues found!`.
- [ ] Native binary builds cleanly on target platform (`flutter build linux` or `flutter build windows`).

### Manual Testing Performed
<!-- Describe manual verification steps executed on your workstation. -->

## Defensive Security & Elevation Review

- [ ] All shell inputs (adapter names, DNS IPs, CLI flags) are strictly regex-validated.
- [ ] Linux `nftables` rules enforce `queue flags bypass` to guarantee zero network disconnection if the DPI engine stops.
- [ ] DNS mutations are preceded by an atomic snapshot via `IDnsSafetyNetService`.
- [ ] No hardcoded passwords, tokens, or plaintext credentials are included.

## Checklist

- [ ] My code adheres to the [Clean Architecture & MVVM guidelines](CONTRIBUTING.md#architectural-principles).
- [ ] I have read and complied with the [Code of Conduct](CODE_OF_CONDUCT.md).
- [ ] I have added appropriate tests covering the new functionality or bug fix.
- [ ] I have updated relevant documentation in `docs/` and `README.md` if applicable.
- [ ] My commit messages adhere to [Conventional Commits](https://www.conventionalcommits.org/).
