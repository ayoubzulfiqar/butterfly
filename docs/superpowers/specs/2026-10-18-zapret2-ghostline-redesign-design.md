# Specification: zapret2 DPI Engine & Ghostline Feature Suite with Silky-Smooth Dual-Mode UI/UX

**Date:** 2026-10-18  
**Status:** Approved by User  
**Scope:** Architectural Overhaul (Butterfly Windows & Linux Desktop)

---

## 1. Executive Summary & Intent

### 1.1 Problem Statement
The previous version of Butterfly relied on a monolithic, single-mode Fluent UI that felt clunky and lacked fluid micro-interactions. Furthermore, DPI bypass was limited to `goodbyedpi` on Windows, leaving Linux users without active DPI desynchronization and lacking modern evasion techniques (multi-split, fake packet TTL auto-tuning, and QUIC packet desync for YouTube).

### 1.2 Objectives & Outcomes
1. **DPI Bypass Modernization:** Replace `goodbyedpi` with **`zapret2`** as the primary cross-platform engine:
   - **Linux:** `nfqws2` via `nftables` queue with non-blocking bypass resilience.
   - **Windows:** `winws2.exe` via `WinDivert` filters.
   - **Profiles:** Port Ghostline's 4 core desync strategies: Light (`z-split`), Medium (`z-disorder`), Strong (`z-fake`), and Extreme (`z-fake-ttl`), plus custom Lua/CLI arguments and legacy GoodbyeDPI fallback.
2. **Driverless TLS Fragmentation (`tlsfrag`):**
   - Pure Dart local HTTP/SOCKS5 proxy splitting TLS ClientHello SNI fields across discrete TCP segments and TLS record layers without requiring kernel drivers.
3. **Bulletproof Safety Net:**
   - Pre-mutation snapshotting of adapter DNS to `state.json` with 3-tier automatic recovery (clean disconnect, exit signal hooks, and ungraceful startup recovery).
4. **Diagnostic Suite:**
   - Integrated Cloudflare Clean-IP Scanner (`cfscan`) benchmarking Anycast CIDRs to discover unpolluted edge IPs and create routing overrides.
5. **Silky-Smooth Dual-Mode UI/UX:**
   - **Simple Mode:** Centered cyber-minimal Hero view featuring a glowing interactive **Neon Power Shield** (with rotating celestial ring animations), a segmented sliding `ProtectionLevels` pill bar, and dynamic layout height physics (`Curves.easeOutCubic`).
   - **Full Studio Mode:** Translucent acrylic dark studio (`#0b0d13`) with live telemetry graphs, DPI engine configuration, DNS catalog, and diagnostic tools.

---

## 2. Architecture & Subsystems

```
                                  ┌────────────────────────────────────────┐
                                  │           BUTTERFLY DESKTOP            │
                                  │  Dual-Mode UI: Simple Shield ◄► Studio │
                                  └───────────────────┬────────────────────┘
                                                      │
                       ┌──────────────────────────────┼──────────────────────────────┐
                       ▼                              ▼                              ▼
      ┌─────────────────────────────────┐   ┌───────────────────┐   ┌─────────────────────────────────┐
      │        DpiService Manager       │   │  DnsSafetyNet     │   │     TlsFragmenterService        │
      │  (Profiles, Monitor, Fallback)  │   │  (state.json)     │   │   (Local User-Space Proxy)      │
      └────────┬───────────────┬────────┘   └───────────────────┘   └────────────────┬────────────────┘
               │               │                                                     │
  (Linux)      ▼               ▼    (Windows)                                        ▼
  ┌──────────────────────┐   ┌──────────────────────┐               ┌─────────────────────────────────┐
  │  nfqws2 + nftables   │   │  winws2 + WinDivert  │               │ TLS ClientHello SNI Splitter:   │
  │  --qnum=510          │   │  --wf-tcp-out=80,443 │               │ • MethodTCP (TCP segmentation)  │
  │  --fwmark=0x10000    │   │  --wf-udp-out=443    │               │ • MethodRecord (TLS multi-frame)│
  │  --user=daemon       │   │  --wf-dup-check=1    │               │ • MethodBoth (Hybrid)           │
  └──────────────────────┘   └──────────────────────┘               └─────────────────────────────────┘
```

### 2.1 Subsystem 1: Dual-Platform `zapret2` Engine

#### Linux Implementation (`LinuxZapret2Engine`)
- **nftables Queue Configuration:**
  - Creates table `inet butterfly_dpi` with two filter chains: `postrouting` (priority 99) and `prerouting` (priority -99).
  - Matches outgoing TCP 80, 443 and UDP 443 packets and sends them to NFQUEUE (`queue num 510 bypass mark 0x10000`).
  - Sets `QueueFlagBypass` so if `nfqws2` stops or terminates, network traffic flows normally without interruption.
  - Skips packets marked with `0x10000` (emitted by `nfqws2`) to prevent packet routing loops.
  - Automatically flushes and removes `table inet butterfly_dpi` upon engine shutdown or system disconnect.
- **Process Spawning:**
  - Spawns `nfqws2 --qnum=510 --fwmark=0x10000 --user=daemon <strategy-flags>` using `pkexec` or elevated root service.

#### Windows Implementation (`WindowsZapret2Engine`)
- **WinDivert Coordination:**
  - Passes `--wf-tcp-out=80,443`, `--wf-udp-out=443` (when QUIC is enabled), and `--wf-dup-check=1` to `winws2.exe`.
  - Cleans up orphan `WinDivert` services prior to startup.
- **Legacy Fallback:**
  - Preserves `goodbyedpi.exe` as an optional secondary engine for systems where `winws2` encounters driver conflicts.

#### Strategy Catalog
1. **Light (`z-split`):** Multisplit (`--lua-desync=multisplit:pos=1,midsld` or `--dpi-desync=split2`).
2. **Medium (`z-disorder`):** Out-of-order segment delivery (`--lua-desync=multidisorder:pos=1,midsld` or `--dpi-desync=disorder2`).
3. **Strong (`z-fake`):** Fake TLS ClientHello with bad checksums + QUIC packet repeat desync (`--lua-desync=fake:blob=fake_default_quic:repeats=6`).
4. **Extreme (`z-fake-ttl`):** Dynamic auto-TTL spoofing (`ip_autottl=-2,3-20`) + faked disorder.
5. **Custom:** User-supplied command-line flags and Lua scripts with syntax validation.

---

### 2.2 Subsystem 2: Driverless TLS ClientHello Fragmentation (`TlsFragmenterService`)

Designed for environments without administrator or root rights:
- **Local Proxy:** Pure Dart HTTP/HTTPS CONNECT and SOCKS5 proxy on `127.0.0.1:8085`.
- **Parsing:** Sniffs initial handshake bytes to identify TLS 1.2/1.3 ClientHello (`0x16 0x03 0x01`).
- **SNI Splitting:**
  - `MethodTCP`: Splits the TCP payload directly across the SNI extension bytes into discrete segments.
  - `MethodRecord`: Splits the ClientHello into multiple TLS record-layer frames within a single payload.
  - `MethodBoth`: Combines TLS record fragmentation and TCP segmentation.

---

### 2.3 Subsystem 3: Bulletproof Safety-Net DNS Restoration (`DnsSafetyNetService`)

- **State Snapshot (`state.json`):**
  - Stored in `%APPDATA%\butterfly\state.json` (Windows) or `~/.config/butterfly/state.json` (Linux).
  - Contains: Network interface IDs, original DHCP/Static state, and list of original DNS IP addresses.
- **Three-Tier Recovery Flow:**
  1. *Clean Disconnect:* User clicks disconnect → original DNS restored → `state.json` removed.
  2. *Process Exit Signal:* Catches `ProcessSignal.sigint`, `ProcessSignal.sigterm`, and `AppLifecycleState.detached` to restore DNS before termination.
  3. *Ungraceful Shutdown Recovery:* On app launch, Butterfly checks if `state.json` exists from an ungraceful shutdown and immediately restores the network to its original state.

---

### 2.4 Subsystem 4: Diagnostic Cloudflare Clean-IP Scanner (`CloudflareScannerService`)

- Probes Cloudflare Anycast IP ranges against `speed.cloudflare.com`.
- Calculates time-to-first-byte (TTFB), round-trip latency, and packet loss.
- Allows the user to select clean IPs and apply them directly as DNS override rules.

---

## 3. UI/UX Design System & Smoothness Architecture

### 3.1 Design Tokens & Cyber-Minimal Palette
- **Obsidian Dark Canvas:** `#0b0d13`
- **Glassmorphic Surface:** `#141824` with 60% opacity and 1px `#1e2640` hairline borders.
- **Neon Emerald (Connected/Clean):** `#00ffa3` / `#10b981`
- **Cyber Cyan (Active/Busy):** `#00d0ff` / `#00f0ff`
- **Neon Amber (Warning):** `#ffb703`
- **Neon Coral (Error/Blocked):** `#ff4d6d`
- **Electric Violet (Studio Accent):** `#8b5cf6`

### 3.2 Component Specifications
1. **Interactive Neon Power Shield (`NeonPowerShield`):**
   - Central power glyph with smooth state transitions (`off`, `busy`, `on`, `err`, `warn`).
   - Outer rotating dashed celestial ring spinning at 18s/rev (idle/on) and 2s/rev (busy).
   - Radial glow emission with breathing drop-shadow effect.
2. **Segmented Protection Levels Bar (`ProtectionLevelsBar`):**
   - Horizontal pill bar (`None`, `Light`, `Medium`, `Strong`, `Extreme`, `Custom`).
   - Gliding animated selection pill (`Curve.easeOutCubic`, 250ms).
3. **Smooth Layout Physics:**
   - Layout transitions driven by `AnimatedSize` and `AnimatedSwitcher` to ensure cards expand and contract smoothly without layout snapping.
4. **Studio Navigation Rail:**
   - 6 tabs: *Overview (Live Telemetry & Status)*, *DPI Studio (zapret2 Engine & Strategies)*, *DNS Resolvers (Catalog & Benchmarks)*, *Proxy & TLS Frag (Driverless Splitter)*, *Diagnostic Tools (CF Scanner & System Tools)*, and *Settings (Safety Net & Startup)*.

---

## 4. Verification & Testing Strategy

1. **Unit Testing:**
   - Test `Zapret2Engine` argument generation for Windows (`--wf-tcp-out`, `--wf-dup-check`) and Linux (`--qnum`, `--fwmark`).
   - Test TLS ClientHello SNI range detection and payload splitting (`MethodTCP`, `MethodRecord`, `MethodBoth`).
   - Test `state.json` serialization, deserialization, and recovery logic.
2. **Integration Testing:**
   - Test `DpiService` lifecycle transitions (`off` → `starting` → `running` → `stopping` → `off`).
   - Verify non-blocking fallback if `nfqws2` or `winws2` binary is absent.
   - Verify safety-net recovery triggers upon simulated process abort.
3. **UI / Widget Testing:**
   - Verify `NeonPowerShield` renders correct colors and ring animation states.
   - Verify `ProtectionLevelsBar` emits correct strategy changes and animates smoothly.
   - Verify tab switching and `AnimatedSize` reflows.
4. **Native Desktop Build & Static Analysis:**
   - `flutter analyze` with 0 issues.
   - Native Linux debug build running at 60/120fps with zero layout overflow.
