import 'dart:io';

import '../../domain/services/i_dpi_service.dart';
import '../../domain/services/i_network_service.dart';
import 'android_network_service.dart';
import 'linux_dpi_service.dart';
import 'linux_network_service.dart';
import 'mock_dpi_service.dart';
import 'mock_network_service.dart';
import 'windows_dpi_service.dart';
import 'windows_network_service.dart';

class PlatformServiceFactory {
  static INetworkService createNetworkService({
    bool? isWindows,
    bool? isLinux,
    bool? isAndroid,
  }) {
    if (isAndroid == true) return AndroidNetworkService();
    if (isLinux == true) return LinuxNetworkService();
    if (isWindows == true) return WindowsNetworkService();

    if (isAndroid == false && isLinux == false && isWindows == false) {
      return MockNetworkService();
    }

    if (Platform.isAndroid) return AndroidNetworkService();
    if (Platform.isLinux) return LinuxNetworkService();
    if (Platform.isWindows) return WindowsNetworkService();

    return MockNetworkService();
  }

  static IDpiService createDpiService({
    bool? isWindows,
    bool? isLinux,
  }) {
    if (isWindows == true) return WindowsDpiService();
    if (isLinux == true) return LinuxDpiService();

    if (isWindows == false && isLinux == false) {
      return MockDpiService();
    }

    if (Platform.isWindows) return WindowsDpiService();
    if (Platform.isLinux) return LinuxDpiService();

    return MockDpiService();
  }
}
