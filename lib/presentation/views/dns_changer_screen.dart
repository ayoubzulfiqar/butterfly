import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dns_changer_viewmodel.dart';

/// Main screen for DNS Changer app.
class DnsChangerScreen extends StatelessWidget {
  const DnsChangerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DNS Changer'),
      ),
      body: Consumer<DnsChangerViewModel>(
        builder: (context, viewModel, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Network Adapter:', style: TextStyle(fontSize: 18)),
                DropdownButton<String>(
                  value: viewModel.selectedAdapter.isEmpty ? null : viewModel.selectedAdapter,
                  items: viewModel.adapters.map((adapter) {
                    return DropdownMenuItem(value: adapter, child: Text(adapter));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) viewModel.selectAdapter(value);
                  },
                ),
                const SizedBox(height: 20),
                const Text('Current DNS:', style: TextStyle(fontSize: 18)),
                Text(viewModel.currentDns),
                const SizedBox(height: 20),
                const Text('Select DNS Provider:', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: ListView.builder(
                    itemCount: viewModel.providers.length,
                    itemBuilder: (context, index) {
                      final provider = viewModel.providers[index];
                      return Card(
                        child: ListTile(
                          title: Text(provider.name),
                          subtitle: Text(provider.description),
                          trailing: ElevatedButton(
                            onPressed: viewModel.isLoading ? null : () => viewModel.changeDns(provider),
                            child: const Text('Apply'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                const Text('DPI Bypass (Advanced):', style: TextStyle(fontSize: 18)),
                const Text('Bypass ISP blocking using GoodbyeDPI. Requires goodbyedpi.exe in app directory.', style: TextStyle(fontSize: 12)),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: viewModel.isLoading || viewModel.isDpiBypassRunning ? null : viewModel.startDpiBypass,
                      child: const Text('Start DPI Bypass'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: viewModel.isLoading || !viewModel.isDpiBypassRunning ? null : viewModel.stopDpiBypass,
                      child: const Text('Stop DPI Bypass'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: viewModel.isLoading ? null : viewModel.restoreDns,
                  child: const Text('Restore to Default'),
                ),
                if (viewModel.isLoading) const CircularProgressIndicator(),
                Text(viewModel.message),
              ],
            ),
          );
        },
      ),
    );
  }
}