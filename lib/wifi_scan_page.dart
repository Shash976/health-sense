import 'dart:convert';
import 'package:health_sense/options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// In AP mode the Arduino always occupies the gateway address.
const _kApIp = '192.168.4.1';
const _kApSsid = 'BioAMP';
const _kApPassword = 'bioamp123';

class WifiScanPage extends StatefulWidget {
  const WifiScanPage({super.key});

  @override
  State<WifiScanPage> createState() => _WifiScanPageState();
}

class _WifiScanPageState extends State<WifiScanPage> {
  bool _connecting = false;
  List<String> _logs = [];

  void _log(String msg) {
    setState(() => _logs.add(msg));
  }

  Future<void> _connect() async {
    if (_connecting) return;
    setState(() {
      _connecting = true;
      _logs = ['Pinging $_kApIp...'];
    });

    final result = await _pingIp(_kApIp);

    if (!mounted) return;

    if (result.responded && result.isBioAmp) {
      _log('BioAMP found. Connecting...');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OptionsPage(deviceIp: _kApIp)),
      );
    } else if (result.responded) {
      _log('Device at $_kApIp responded as "${result.name ?? "Unknown"}" — not a BioAMP.');
      _log('Make sure your phone is connected to the "$_kApSsid" Wi-Fi network.');
    } else {
      _log('No response from $_kApIp.');
      _log('Is your phone connected to "$_kApSsid"?');
    }

    if (mounted) setState(() => _connecting = false);
  }

  Future<void> _manualIpFlow() async {
    final ipController = TextEditingController();
    final ip = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter BioAMP IP'),
        content: TextField(
          controller: ipController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: const InputDecoration(hintText: 'e.g. 192.168.4.1'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ipController.text.trim()),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    ipController.dispose();

    if (ip == null || ip.isEmpty) return;

    // Basic IPv4 format check.
    final ipv4 = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipv4.hasMatch(ip)) {
      _log('Invalid IP address: "$ip"');
      return;
    }

    if (!mounted) return;
    setState(() {
      _connecting = true;
      _logs.add('Pinging $ip...');
    });

    // Show spinner while pinging
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    final result = await _pingIp(ip);
    if (mounted) Navigator.of(context).pop(); // dismiss spinner

    if (result.responded && result.isBioAmp) {
      _log('BioAMP confirmed at $ip.');
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OptionsPage(deviceIp: ip)));
      }
    } else {
      final msg = result.responded
          ? 'Responded as "${result.name ?? "Unknown"}", not identified as BioAMP.'
          : 'No response from $ip.';
      _log(msg);

      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Warning'),
          content: Text('$msg\n\nConnect anyway?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
          ],
        ),
      );

      if (proceed == true && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OptionsPage(deviceIp: ip)));
      }
    }

    if (mounted) setState(() => _connecting = false);
  }

  Future<({bool responded, bool isBioAmp, String? name})> _pingIp(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip/whoami'))
          .timeout(const Duration(milliseconds: 2000));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final name = data is Map ? data['name'] as String? : null;
        return (responded: true, isBioAmp: name == 'BioAMP', name: name);
      }
      return (responded: true, isBioAmp: false, name: null);
    } catch (_) {
      return (responded: false, isBioAmp: false, name: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to BioAMP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AP connection instructions card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 1 — Connect your phone to:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.wifi),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_kApSsid,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Password: $_kApPassword',
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Step 2 — Tap Connect below.',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _connecting ? null : _connect,
              icon: _connecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find),
              label: Text(_connecting ? 'Connecting...' : 'Connect to BioAMP'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _connecting ? null : _manualIpFlow,
              child: const Text('Enter IP manually'),
            ),
            const Divider(height: 32),
            const Text('Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (_, i) =>
                    Text(_logs[i], style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
