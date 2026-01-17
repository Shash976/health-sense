import 'dart:convert';
import 'dart:io';
import 'package:health_sense/options.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'network_utils.dart';
import 'package:flutter/foundation.dart';

class WifiScanPage extends StatefulWidget {
  const WifiScanPage({super.key});

  @override
  State<WifiScanPage> createState() => _WifiScanPageState();
}

class _PingResult {
  final bool responded;
  final bool isBioAmp;
  final String? name;
  final int? statusCode;
  const _PingResult({
    required this.responded,
    required this.isBioAmp,
    this.name,
    this.statusCode,
  });
}

class _WifiScanPageState extends State<WifiScanPage> {
  List<Map<String, String>> devices = [];
  bool isScanning = false;
  List<String> scanLogs = [];

  Future<void> _scanNetwork() async {
    setState(() {
      isScanning = true;
      devices = [];
      scanLogs = ["🔍 Looking up bioamp.local..."];
    });

    final host = 'bioamp.local';
    debugPrint("📡 Pinging $host");
    final result = await _pingIp(host);

    if (mounted) {
      setState(() {
        if (result.responded && result.isBioAmp) {
          devices.add({'ip': host, 'name': result.name ?? 'BioAMP'});
          scanLogs.add("✅ Found BioAMP at $host");
        } else if (result.responded) {
          scanLogs.add("🟡 $host responded as ${result.name ?? 'Unknown'}, not identified as BioAMP.");
        } else {
          scanLogs.add("❌ No response from $host.");
        }
        isScanning = false;
      });
    }
  }

  Future<_PingResult> _pingIp(String ip) async {
    final url = Uri.parse('http://$ip/whoami');
    try {
      final response = await http.get(url).timeout(const Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final name = data is Map && data.containsKey('name') ? data['name'] as String? : null;
        final isBio = name == 'BioAMP';
        return _PingResult(responded: true, isBioAmp: isBio, name: name, statusCode: 200);
      } else {
        return _PingResult(responded: true, isBioAmp: false, name: null, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('Ping $ip failed: $e');
      return const _PingResult(responded: false, isBioAmp: false);
    }
  }

  Future<void> _manualIpFlow() async {
    final ip = await showDialog<String>(
      context: context,
      builder: (context) {
        String input = '';
        return AlertDialog(
          title: const Text('Enter BioAMP IP'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 192.168.137.158'),
            onChanged: (v) => input = v.trim(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(input), child: const Text('Ping')),
          ],
        );
      },
    );

    if (ip == null || ip.isEmpty) return;

    setState(() {
      scanLogs.add('➡️ Manually pinging $ip...');
    });

    // show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _pingIp(ip);

    if (mounted) Navigator.of(context).pop(); // close progress

    if (result.responded && result.isBioAmp) {
      setState(() {
        devices.add({'ip': ip, 'name': result.name ?? 'BioAMP'});
        scanLogs.add('✅ $ip is a BioAMP. Selecting device.');
      });
      // navigate to options for selected device
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OptionsPage(deviceIp: ip)),
        );
      }
      return;
    }

    // Not responsive or not BioAMP -> show warning with option to continue anyway
    final message = result.responded
        ? 'Device responded${result.name != null ? ' as ${result.name}' : ''}, but it is not identified as BioAMP.'
        : 'No response from $ip.';
    setState(() => scanLogs.add('❌ $message'));

    final choice = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: Text('$message\n\nDo you want to continue anyway?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continue Anyway')),
          ],
        );
      },
    );

    if (choice == true) {
      // Add the IP (unknown) and navigate despite warning
      setState(() {
        devices.add({'ip': ip, 'name': result.name ?? 'Unknown'});
        scanLogs.add('⚠️ Continuing with $ip despite warning.');
      });
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OptionsPage(deviceIp: ip)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Wi-Fi Devices')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isScanning ? null : _scanNetwork,
              child: Text(isScanning ? 'Scanning...' : 'Scan Network'),
            ),
            const SizedBox(height: 20),
            const Text("Discovered Devices", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              flex: 2,
              child: devices.isEmpty
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No BioAMP devices found.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: isScanning ? null : _manualIpFlow,
                    child: const Text('Enter IP manually'),
                  ),
                ],
              )
                  : ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    title: Text(device['name'] ?? 'Unknown'),
                    subtitle: Text(device['ip']!),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OptionsPage(deviceIp: device['ip']!),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            const Text("Debug Log", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              flex: 3,
              child: ListView.builder(
                itemCount: scanLogs.length,
                itemBuilder: (context, index) {
                  return Text(scanLogs[index], style: const TextStyle(fontSize: 12));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
