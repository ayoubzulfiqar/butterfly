# Security Policy

The Butterfly project takes the security, resilience, and privacy of its users seriously. Given that Butterfly interacts directly with low-level networking subsystems, packet queues (`nftables`/`NFQUEUE` on Linux, `WinDivert` on Windows), and elevated administrative commands (`pkexec`, `netsh`, `resolvectl`), we enforce strict defensive security practices.

This policy outlines how to report vulnerabilities, our disclosure lifecycle, and our security design principles.

---

## Supported Versions

Only the latest active major/minor release branch receives official security updates and patches.

| Version | Supported          | Security Patches |
| ------- | ------------------ | ---------------- |
| 2.x     | :white_check_mark: | Active           |
| 1.x     | :x:                | Deprecated       |
| < 1.0   | :x:                | End of Life      |

If you are using an older version, please upgrade to the latest stable release to ensure you have all security mitigations.

---

## Reporting a Vulnerability

**Please do not report security vulnerabilities via public GitHub issues, discussions, or pull requests.**

If you discover or suspect a security vulnerability in Butterfly, report it confidentially:

1. **Email**: Send your findings to **[security@butterfly-project.org](mailto:security@butterfly-project.org)**.
2. **Subject**: `[SECURITY VULNERABILITY] <Component or Short Summary>`
3. **Include the following information**:
   - Component affected (e.g., `LinuxDpiService`, `Zapret2LinuxEngine`, `TlsFragmenterServiceImpl`, `DnsSafetyNetService`).
   - Detailed description of the vulnerability and its potential impact.
   - Proof of Concept (PoC) or step-by-step instructions to reproduce.
   - Operating system and environment details (distribution, kernel, Windows version, elevation level).
   - Any suggested remediations or workarounds.

### Response Timeline & SLA

We are committed to handling security vulnerabilities responsibly:

| Milestone | Target Response Time |
| :--- | :--- |
| **Initial Acknowledgment** | Within **48 hours** |
| **Triage & Severity Assessment** | Within **5 business days** |
| **Patch Development & Testing** | Within **14 to 30 days** (depending on complexity) |
| **Coordinated Public Advisory & Release** | Upon patch deployment |

We request that you adhere to standard **Coordinated Vulnerability Disclosure (CVD)** principles and afford our team reasonable time to develop and test a fix before publicly releasing exploit details.

---

## Security Architecture & Defensive Principles

Butterfly incorporates several layers of defensive engineering:

### 1. Zero Shell Injection & Parameterized Execution
- Shell execution does **not** concatenate arbitrary user input into command strings.
- Network interface names and IP addresses undergo strict character-whitelisting:
  - IP addresses must validate against standard IPv4/IPv6 address regexes (`^((25[0-5]|...))$`).
  - Interface names must match safe alphanumeric identifier formats (`^[a-zA-Z0-9_.\-]+$`).
- All scripts (such as `nftables` rules) are supplied either via direct binary arguments or safely streamed through standard input (`stdin`) to avoid command-line parsing vulnerabilities.

### 2. Non-Destructive Fail-Open DPI Interception
- When configuring Linux `nftables` queue rules for `nfqws2`, rules explicitly enforce:
  ```nft
  queue flags bypass to 510
  ```
  The `bypass` flag ensures that if the DPI engine process terminates, crashes, or is killed, incoming and outgoing packets bypass the queue uninterrupted rather than dropping connection state.

### 3. Bulletproof DNS State Restoration (`Safety Net`)
- Whenever network adapter DNS configurations are mutated, Butterfly serializes a pre-flight snapshot to `state.json`.
- In the event of an ungraceful termination, system freeze, or crash, the runtime automatically recovers the snapshot on next boot and restores original DHCP/static DNS parameters.

### 4. Userspace Driverless TLS Proxy Isolation
- The TLS ClientHello fragmentation proxy runs entirely in non-privileged user-space on local loopback (`127.0.0.1:8085`).
- It strictly acts as an HTTP CONNECT tunnel without injecting or mutating unencrypted application payloads, ensuring end-to-end TLS integrity.

---

## Out of Scope

The following scenarios are considered outside the scope of Butterfly's threat model:
- Attacks requiring unrestricted physical access or root/administrator access already established on the host machine.
- Vulnerabilities in third-party operating system components (e.g., vulnerabilities inside the Linux kernel `nfnetlink_queue` subsystem or the Windows TCP/IP stack itself).
- Denial-of-service against third-party public DNS providers.
- Attacks relying on social engineering or installing untrusted third-party binaries onto the host.

---

Thank you for contributing to the safety and security of the Butterfly open-source ecosystem.
