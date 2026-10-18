import 'package:flutter/foundation.dart';

/// View mode for the application interface: simple one-click shield or full multi-workspace studio.
enum AppViewMode { simple, studio }

/// Navigation destinations available in the enterprise desktop shell.
enum NavigationTab {
  dashboard,
  dnsResolvers,
  dpiBypass,
  proxyFrag,
  tools,
  diagnostics,
}

/// Manages active navigation tab and global UI view switching.
class NavigationViewModel extends ChangeNotifier {
  NavigationTab _currentTab = NavigationTab.dashboard;
  AppViewMode _viewMode;

  NavigationViewModel({AppViewMode initialMode = AppViewMode.simple})
      : _viewMode = initialMode;

  NavigationTab get currentTab => _currentTab;
  int get currentIndex => _currentTab.index;
  AppViewMode get viewMode => _viewMode;

  void setViewMode(AppViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  void toggleViewMode() {
    _viewMode =
        _viewMode == AppViewMode.simple ? AppViewMode.studio : AppViewMode.simple;
    notifyListeners();
  }

  void selectTab(NavigationTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      notifyListeners();
    }
  }

  void selectIndex(int index) {
    if (index >= 0 && index < NavigationTab.values.length) {
      selectTab(NavigationTab.values[index]);
    }
  }
}
