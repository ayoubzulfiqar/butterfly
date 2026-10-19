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
    final win = isWindows ?? Platform.isWindows;
    final linux = isLinux ?? Platform.isLinux;
    final android = isAndroid ?? Platform.isAndroid;

    if (win) {
      return WindowsNetworkService();
    } else if (linux) {
      return LinuxNetworkService();
    } else if (android) {
      return AndroidNetworkService();
    } else {
      return MockNetworkService();
    }
  }

  static IDpiService createDpiService({
    bool? isWindows,
    bool? isLinux,
  }) {
    final win = isWindows ?? Platform.isWindows;
    final linux = isLinux ?? Platform.isLinux;

    if (win) {
      return WindowsDpiService();
    } else if (linux) {
      return LinuxDpiService();
    } else {
      return MockDpiService();
    }
  }
}
