# Android Platform Support & Adaptive Mobile Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable native Android support in Butterfly with an unrooted local `VpnService` for DNS capture, `AndroidNetworkService` implementation, `PlatformServiceFactory` integration, adaptive responsive UI (bottom navigation bar on phone screens < 600dp), and successful Android APK compilation.

**Architecture:** Model-View-ViewModel (MVVM) with clean architecture separation. Platform-adaptive service layer dispatching to an Android Kotlin `VpnService` via Flutter `MethodChannel('butterfly/vpn')` for unrooted DNS packet routing, coupled with a userspace driverless TLS fragmentation proxy. Responsive UI using `LayoutBuilder` to toggle between desktop `NavigationRail` and mobile `NavigationBar`.

**Tech Stack:** Flutter 3.x, Dart 3, Kotlin, Android SDK 34 (`VpnService`, `ConnectivityManager`), Gradle 8.x.

**Spec:** [docs/superpowers/specs/2026-10-19-android-support-design.md](file:///home/sensei/Projects/flutter/butterfly/docs/superpowers/specs/2026-10-19-android-support-design.md)

## Global Constraints
- Target SDK: 34 (Android 14) / Minimum SDK: 24 (Android 7.0 Nougat).
- Package Identifier: `org.butterfly.app`.
- Root Dependency: Zero root requirement for baseline functionality; all routing uses standard Android `VpnService`.
- UI Responsiveness: Zero layout jank or `RenderFlex` overflows on mobile viewports down to 360dp width.
- Existing Desktop Compatibility: Zero regressions on Linux (`systemd-resolved`/`nftables`) and Windows (`netsh`/`WinDivert`).

## Review Focus
1. **VPN Permission Rejection**: Verify `AndroidNetworkService` catches user cancellation of Android's system VPN prompt (`ACTION_VPN_PREPARE`) without throwing an unhandled exception or leaving the app in a desynced "applying" state.
2. **Mobile Viewport Overflows**: Verify that on mobile phone viewports (< 600dp width) all workspaces (*Dashboard, Resolvers, Tools, Proxy Frag*) scroll vertically without triggering horizontal or vertical `RenderFlex` overflows.
3. **Network Transport Switching**: Verify `AndroidNetworkService.getAdapters()` gracefully reports cellular vs. Wi-Fi transitions without crashing when disconnected.
4. **Clean Loopback Proxy Isolation**: Verify `TlsFragmenterServiceImpl` on `127.0.0.1:8085` runs without port conflict and is accessible by local mobile web browsers.
5. **Static Analysis & Desktop Regressions**: Verify `flutter analyze` reports 0 issues and all existing 90 desktop tests pass unmodified.

---

### Task 1: Android Platform Scaffold & Native Gradle Setup

**Files:**
- Create: `android/` directory via `flutter create --platforms=android .`
- Modify: `android/app/build.gradle`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/src/main/res/mipmap-*/ic_launcher.png` (via Python PIL script from `assets/icon.png`)
- Test: Build configuration check via `flutter doctor` and Gradle wrapper presence

- [ ] **Step 1: Scaffold native Android platform files using Flutter CLI**
  - Run: `flutter create --platforms=android .`
  - Verify `android/` directory is created with Gradle files without overwriting Linux/Windows or lib files.
- [ ] **Step 2: Configure `android/app/build.gradle` and namespace**
  - Set `namespace = "org.butterfly.app"`.
  - Set `compileSdk = 34`, `minSdk = 24`, `targetSdk = 34`.
  - Set `applicationId = "org.butterfly.app"`.
- [ ] **Step 3: Update `android/app/src/main/AndroidManifest.xml`**
  - Add permissions:
    - `android.permission.INTERNET`
    - `android.permission.ACCESS_NETWORK_STATE`
    - `android.permission.FOREGROUND_SERVICE`
    - `android.permission.FOREGROUND_SERVICE_SPECIAL_USE`
  - Configure `<service android:name=".ButterflyVpnService" android:permission="android.permission.BIND_VPN_SERVICE" android:exported="false">`.
- [ ] **Step 4: Generate Android launcher mipmap icons from `assets/icon.png`**
  - Write and run Python script to generate `mipmap-mdpi` (48x48), `mipmap-hdpi` (72x72), `mipmap-xhdpi` (96x96), `mipmap-xxhdpi` (144x144), `mipmap-xxxhdpi` (192x192).
- [ ] **Step 5: Commit Android scaffolding**
  - `git commit -m "feat(android): scaffold Android platform with Gradle 8, SDK 34, and cyber launcher icons"`

---

### Task 2: Native Android `ButterflyVpnService` & MethodChannel

**Files:**
- Create: `android/app/src/main/kotlin/org/butterfly/app/ButterflyVpnService.kt`
- Modify: `android/app/src/main/kotlin/org/butterfly/app/MainActivity.kt`
- Test: Unit/mock verification in Task 3

- [ ] **Step 1: Implement `ButterflyVpnService.kt`**
  - Extend `android.net.VpnService`.
  - In `onStartCommand`:
    - Read `primaryDns` and `secondaryDns` from Intent.
    - Build virtual interface via `VpnService.Builder()`:
      - Set session: `"Butterfly DNS Shield"`.
      - Add address: `10.0.0.2`, prefix `32`.
      - Add routes: `primaryDns/32`, optional `secondaryDns/32`.
      - Add DNS servers: `addDnsServer(primaryDns)`.
      - Set blocking: `setBlocking(true)`.
      - Establish `ParcelFileDescriptor`.
    - Create foreground notification channel (`"butterfly_vpn"`) and start foreground service with notification.
  - In `onDestroy`:
    - Close interface descriptor, remove notification, stop foreground service.
- [ ] **Step 2: Implement `MainActivity.kt` MethodChannel handler**
  - Create `MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "butterfly/vpn")`.
  - Handle `startVpn`:
    - Check `VpnService.prepare(this)`. If intent returned, launch via `startActivityForResult(intent, VPN_REQUEST_CODE)`.
    - If already prepared, start `ButterflyVpnService` with action `ACTION_CONNECT`.
  - Handle `stopVpn`:
    - Stop `ButterflyVpnService` with action `ACTION_DISCONNECT`.
  - Handle `getVpnStatus`:
    - Return `mapOf("isRunning" to isRunning, "dnsServers" to activeDns)`.
  - Handle `getNetworkTransport`:
    - Query `ConnectivityManager` and return `"Wi-Fi"`, `"Cellular"`, or `"Ethernet"`.
- [ ] **Step 3: Commit native Android VPN service**
  - `git commit -m "feat(android): implement ButterflyVpnService and MainActivity MethodChannel"`

---

### Task 3: Dart `AndroidNetworkService` & `PlatformServiceFactory` Dispatch

**Files:**
- Create: `lib/data/services/android_network_service.dart`
- Modify: `lib/data/services/platform_service_factory.dart`
- Test: `test/unit/android_network_service_test.dart`

- [ ] **Step 1: Write unit tests for `AndroidNetworkService`**
  - Mock `MethodChannel('butterfly/vpn')` via `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger`.
  - Test `getAdapters()` maps transport string to `NetworkAdapter`.
  - Test `getCurrentDns()` returns active DNS from channel.
  - Test `setDns()` dispatches `startVpn` with IPv4 arguments.
  - Test `restoreDns()` dispatches `stopVpn`.
- [ ] **Step 2: Run test to verify it fails (`flutter test test/unit/android_network_service_test.dart`)**
- [ ] **Step 3: Implement `AndroidNetworkService`**
  - Implement `INetworkService` methods using `const MethodChannel('butterfly/vpn')`.
  - Handle platform channel exceptions gracefully without throwing unhandled errors.
- [ ] **Step 4: Update `PlatformServiceFactory.createNetworkService()`**
  - Add `if (Platform.isAndroid) return AndroidNetworkService();`.
- [ ] **Step 5: Run tests and ensure all pass**
  - Run: `flutter test test/unit/android_network_service_test.dart`
- [ ] **Step 6: Commit Android network service**
  - `git commit -m "feat(android): implement AndroidNetworkService and PlatformServiceFactory dispatch"`

---

### Task 4: Adaptive Responsive Navigation & Mobile UI Layout

**Files:**
- Modify: `lib/presentation/views/main_shell_screen.dart`
- Modify: `lib/presentation/views/pages/simple_shield_screen.dart`
- Test: `test/widget/adaptive_mobile_shell_test.dart`

- [ ] **Step 1: Write failing widget tests for adaptive responsive shell**
  - Test 1: When viewport is compact (`Size(380, 800)`), `MainShellScreen` displays `NavigationBar` at bottom and no `NavigationRail`.
  - Test 2: When viewport is wide (`Size(1280, 800)`), `MainShellScreen` displays `NavigationRail` and no bottom `NavigationBar`.
  - Test 3: Tapping bottom navigation bar destinations switches active index cleanly without `RenderFlex` overflow.
- [ ] **Step 2: Run test to verify it fails (`flutter test test/widget/adaptive_mobile_shell_test.dart`)**
- [ ] **Step 3: Implement responsive `MainShellScreen` layout**
  - In `build(BuildContext context)`:
    - Use `LayoutBuilder(builder: (context, constraints) { ... })`.
    - Determine `final isCompact = constraints.maxWidth < 600;`.
    - If `isCompact`:
      - Return `Scaffold` with cyber-themed `bottomNavigationBar: NavigationBar(...)` using Obsidian dark surface (`#121824`) and cyan indicators (`#00F0FF`).
      - In body: render active workspace via `IndexedStack(index: navVm.currentTabIndex, children: _pages)`.
    - If not `isCompact`:
      - Return existing desktop layout with `Row(children: [NavigationRail(...), Expanded(child: ...)])`.
- [ ] **Step 4: Make `SimpleShieldScreen` dynamically scale for mobile screens**
  - In `SimpleShieldScreen`, check `constraints.maxWidth`:
    - Scale outer radius of `NeonPowerShield` (e.g. `isCompact ? 220 : 280`).
    - Ensure HUD telemetry badges wrap in a responsive flex row/column.
- [ ] **Step 5: Run widget tests and verify 100% pass rate**
  - Run: `flutter test test/widget/adaptive_mobile_shell_test.dart`
- [ ] **Step 6: Commit responsive mobile UI**
  - `git commit -m "feat(ui): add adaptive responsive NavigationBar for mobile phone viewports"`

---

### Task 5: End-to-End Verification & Native Android Build

**Files:**
- Review: Entire test suite
- Test: `flutter test`
- Static Analysis: `flutter analyze`
- Native Compilation: `flutter build apk --debug`

- [ ] **Step 1: Run the full test suite**
  - Run: `flutter test`
  - Ensure all 90+ unit and widget tests pass.
- [ ] **Step 2: Run static analysis**
  - Run: `flutter analyze`
  - Ensure 0 warnings and 0 hints.
- [ ] **Step 3: Build Android debug APK**
  - Run: `flutter build apk --debug`
  - Verify output APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.
- [ ] **Step 4: Update Documentation**
  - Update `README.md` to reflect Android support and APK build instructions.
- [ ] **Step 5: Commit final Android delivery**
  - `git commit -m "chore(android): verify test suite, 0 lints, and clean APK build"`

---
