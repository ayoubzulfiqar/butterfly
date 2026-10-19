import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_theme.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../viewmodels/network_dns_viewmodel.dart';
import '../widgets/elevation_banner.dart';
import '../widgets/status_badge.dart';
import 'pages/dashboard_page.dart';
import 'pages/diagnostics_page.dart';
import 'pages/dns_resolvers_page.dart';
import 'pages/dpi_bypass_page.dart';
import 'pages/proxy_fragmentation_page.dart';
import 'pages/simple_shield_screen.dart';
import 'pages/tools_page.dart';

/// Primary desktop shell providing Windows 11 Fluent navigation and header.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navVm = context.watch<NavigationViewModel>();
    final dnsVm = context.watch<NetworkDnsViewModel>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      child: navVm.viewMode == AppViewMode.simple
          ? const SimpleShieldScreen(key: ValueKey('simple_shield'))
          : _buildStudioShell(context, navVm, dnsVm),
    );
  }

  Widget _buildStudioShell(
    BuildContext context,
    NavigationViewModel navVm,
    NetworkDnsViewModel dnsVm,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        if (isCompact) {
          return Scaffold(
            key: const ValueKey('studio_shell'),
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  ElevationBanner(isElevated: dnsVm.isAdministrator),
                  _buildCompactHeader(context, navVm, dnsVm),
                const Divider(height: 1),
                Expanded(
                  child: IndexedStack(
                    index: navVm.currentIndex,
                    children: const [
                      DashboardPage(),
                      DnsResolversPage(),
                      DpiBypassPage(),
                      ProxyFragmentationPage(),
                      ToolsPage(),
                      DiagnosticsPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: const Color(0xFF121824),
                indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    );
                  }
                  return const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(
                      color: AppTheme.primaryBlue,
                      size: 22,
                    );
                  }
                  return const IconThemeData(color: Colors.grey, size: 20);
                }),
              ),
              child: NavigationBar(
                selectedIndex: navVm.currentIndex,
                onDestinationSelected: navVm.selectIndex,
                backgroundColor: const Color(0xFF121824),
                indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.dns_outlined),
                    selectedIcon: Icon(Icons.dns_rounded),
                    label: 'DNS Resolvers',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.shield_outlined),
                    selectedIcon: Icon(Icons.shield_rounded),
                    label: 'DPI Bypass',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.alt_route_outlined),
                    selectedIcon: Icon(Icons.alt_route_rounded),
                    label: 'Proxy & TLS Frag',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.build_outlined),
                    selectedIcon: Icon(Icons.build_rounded),
                    label: 'Tools',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.terminal_outlined),
                    selectedIcon: Icon(Icons.terminal_rounded),
                    label: 'Diagnostics',
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          key: const ValueKey('studio_shell'),
          body: Column(
            children: [
              ElevationBanner(isElevated: dnsVm.isAdministrator),
              Expanded(
                child: Row(
                  children: [
                    _buildNavigationRail(context, navVm),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopHeader(context, navVm, dnsVm),
                          const Divider(height: 1),
                          Expanded(
                            child: IndexedStack(
                              index: navVm.currentIndex,
                              children: const [
                                DashboardPage(),
                                DnsResolversPage(),
                                DpiBypassPage(),
                                ProxyFragmentationPage(),
                                ToolsPage(),
                                DiagnosticsPage(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactHeader(
    BuildContext context,
    NavigationViewModel navVm,
    NetworkDnsViewModel dnsVm,
  ) {
    final title = _getTitleForTab(navVm.currentTab);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Simple Shield',
            child: OutlinedButton.icon(
              icon: const Icon(Icons.shield_outlined, size: 14),
              label: const Text('Simple Shield'),
              onPressed: () => navVm.setViewMode(AppViewMode.simple),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: dnsVm.isFlushingCache
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cleaning_services_rounded, size: 18),
            tooltip: 'Flush Cache',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: dnsVm.isFlushingCache ? null : dnsVm.flushDnsCache,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    NavigationViewModel navVm,
  ) {
    return NavigationRail(
      selectedIndex: navVm.currentIndex,
      onDestinationSelected: navVm.selectIndex,
      extended: true,
      minExtendedWidth: 210,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.alt_route_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Butterfly',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Enterprise Suite',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.dns_outlined),
          selectedIcon: Icon(Icons.dns_rounded),
          label: Text('DNS Resolvers'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shield_outlined),
          selectedIcon: Icon(Icons.shield_rounded),
          label: Text('DPI Bypass'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.alt_route_outlined),
          selectedIcon: Icon(Icons.alt_route_rounded),
          label: Text('Proxy & TLS Frag'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build_rounded),
          label: Text('Tools'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.terminal_outlined),
          selectedIcon: Icon(Icons.terminal_rounded),
          label: Text('Diagnostics'),
        ),
      ],
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    NavigationViewModel navVm,
    NetworkDnsViewModel dnsVm,
  ) {
    final title = _getTitleForTab(navVm.currentTab);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.shield_outlined, size: 14),
                label: const Text('Simple Shield'),
                onPressed: () => navVm.setViewMode(AppViewMode.simple),
              ),
              const SizedBox(width: 12),
              StatusBadge(
                label: dnsVm.isAdministrator
                    ? 'Administrator'
                    : 'Standard User (Non-Elevated)',
                isSuccess: dnsVm.isAdministrator,
                icon: dnsVm.isAdministrator
                    ? Icons.verified_user_rounded
                    : Icons.gpp_maybe_rounded,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: dnsVm.isFlushingCache
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cleaning_services_rounded, size: 14),
                label: const Text('Flush Cache'),
                onPressed:
                    dnsVm.isFlushingCache ? null : dnsVm.flushDnsCache,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTitleForTab(NavigationTab tab) {
    switch (tab) {
      case NavigationTab.dashboard:
        return 'Network & DNS Dashboard';
      case NavigationTab.dnsResolvers:
        return 'DNS Resolver Catalog';
      case NavigationTab.dpiBypass:
        return 'zapret2 DPI Bypass Studio';
      case NavigationTab.proxyFrag:
        return 'Driverless TLS Proxy & Fragmentation';
      case NavigationTab.tools:
        return 'Tools & Diagnostics Studio';
      case NavigationTab.diagnostics:
        return 'Diagnostics & Live Telemetry';
    }
  }
}
