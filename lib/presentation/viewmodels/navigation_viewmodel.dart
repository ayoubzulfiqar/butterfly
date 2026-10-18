import 'package:flutter/foundation.dart';

/// Navigation destinations available in the enterprise desktop shell.
enum NavigationTab { dashboard, dnsResolvers, dpiBypass, tools, diagnostics }

/// Manages active navigation tab and global UI view switching.
class NavigationViewModel extends ChangeNotifier {
  NavigationTab _currentTab = NavigationTab.dashboard;

  NavigationTab get currentTab => _currentTab;
  int get currentIndex => _currentTab.index;

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
