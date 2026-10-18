import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/dns_provider.dart';

/// Modal dialog for adding a custom DNS resolver.
class CustomDnsDialog extends StatefulWidget {
  final void Function(DnsProvider provider) onAdd;

  const CustomDnsDialog({super.key, required this.onAdd});

  @override
  State<CustomDnsDialog> createState() => _CustomDnsDialogState();
}

class _CustomDnsDialogState extends State<CustomDnsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _ipv4PrimaryController = TextEditingController();
  final _ipv4SecondaryController = TextEditingController();
  final _ipv6PrimaryController = TextEditingController();
  final _ipv6SecondaryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _ipv4PrimaryController.dispose();
    _ipv4SecondaryController.dispose();
    _ipv6PrimaryController.dispose();
    _ipv6SecondaryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final ipv4 = <String>[];
      if (_ipv4PrimaryController.text.trim().isNotEmpty) {
        ipv4.add(_ipv4PrimaryController.text.trim());
      }
      if (_ipv4SecondaryController.text.trim().isNotEmpty) {
        ipv4.add(_ipv4SecondaryController.text.trim());
      }

      final ipv6 = <String>[];
      if (_ipv6PrimaryController.text.trim().isNotEmpty) {
        ipv6.add(_ipv6PrimaryController.text.trim());
      }
      if (_ipv6SecondaryController.text.trim().isNotEmpty) {
        ipv6.add(_ipv6SecondaryController.text.trim());
      }

      final provider = DnsProvider(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : 'Custom user-configured DNS resolver',
        category: DnsCategory.custom,
        features: const ['Custom'],
        ipv4: ipv4,
        ipv6: ipv6,
        isCustom: true,
      );

      widget.onAdd(provider);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom DNS Resolver'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Provider Name',
                    hintText: 'e.g. Pi-hole / Corporate DNS',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Internal network or ad-blocking DNS',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ipv4PrimaryController,
                        decoration: const InputDecoration(
                          labelText: 'IPv4 Primary',
                          hintText: '1.1.1.1',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            if (_ipv6PrimaryController.text.trim().isEmpty) {
                              return 'Primary IP required';
                            }
                            return null;
                          }
                          final parsed = InternetAddress.tryParse(v.trim());
                          if (parsed == null ||
                              parsed.type != InternetAddressType.IPv4) {
                            return 'Invalid IPv4 address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _ipv4SecondaryController,
                        decoration: const InputDecoration(
                          labelText: 'IPv4 Secondary',
                          hintText: '1.0.0.1',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final parsed = InternetAddress.tryParse(v.trim());
                          if (parsed == null ||
                              parsed.type != InternetAddressType.IPv4) {
                            return 'Invalid IPv4';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ipv6PrimaryController,
                        decoration: const InputDecoration(
                          labelText: 'IPv6 Primary (optional)',
                          hintText: '2606:4700::1111',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final parsed = InternetAddress.tryParse(v.trim());
                          if (parsed == null ||
                              parsed.type != InternetAddressType.IPv6) {
                            return 'Invalid IPv6 address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _ipv6SecondaryController,
                        decoration: const InputDecoration(
                          labelText: 'IPv6 Secondary (optional)',
                          hintText: '2606:4700::1001',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final parsed = InternetAddress.tryParse(v.trim());
                          if (parsed == null ||
                              parsed.type != InternetAddressType.IPv6) {
                            return 'Invalid IPv6';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save Provider'),
        ),
      ],
    );
  }
}
