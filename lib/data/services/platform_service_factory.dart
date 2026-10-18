import 'dart:io';

import '../../domain/services/i_dpi_service.dart';
import '../../domain/services/i_network_service.dart';
import 'linux_dpi_service.dart';
import 'linux_network_service.dart';
import 'mock_dpi_service.dart';
import 'mock_network_service.dart';
import 'windows_dpi_service.dart';
import 'windows_network_service.dart';

class PlatformServiceFactory {
  static INetworkService createNetworkService() {
    if (Platform.isWindows) {
      return WindowsNetworkService();
    } else if (Platform.isLinux) {
      return LinuxNetworkService();
    } else {
      return MockNetworkService();
    }
  }

  static IDpiService createDpiService() {
    if (Platform.isWindows) {
      return WindowsDpiService();
    } else if (Platform.isLinux) {
      return LinuxDpiService();
    } else {
      return MockDpiService();
    }
  }
}
