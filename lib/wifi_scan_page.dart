import 'dart:convert';
import 'dart:io';
import 'package:bio_amp/options.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WifiScanPage extends StatefulWidget {
  const WifiScanPage({super.key});

  @override
  State<WifiScanPage> createState() => _WifiScanPageState();
}

class _WifiScanPageState extends State<WifiScanPage> {
  List<Map<String, String>> devices = [];
  bool isScanning = false;
  List<String> scanLogs = [];

  Future<void> _scanNetwork() async {
    setState(() {
      isScanning = true;
      devices = [];
      scanLogs = ["🔍 Starting scan..."];
    });

    final localIps = await _getAllLocalIps();
    if (localIps.isEmpty) {
      setState(() {
        isScanning = false;
        scanLogs.add("❌ Could not find any local IPs.");
      });
      return;
    }

    for (final localIp in localIps) {
      final subnet = localIp.substring(0, localIp.lastIndexOf('.') + 1);
      scanLogs.add("📡 Scanning subnet: $subnet");
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet$i';
        _checkDevice(ip);
        await Future.delayed(const Duration(milliseconds: 20)); // Avoid flooding
      }
    }
  }

  Future<void> _checkDevice(String ip) async {
    final url = Uri.parse('http://$ip/whoami');
    try {
      scanLogs.add("➡️ Pinging $ip...");
      debugPrint("➡️ Pinging $ip...");
      final response = await http.get(url).timeout(const Duration(milliseconds: 700));
      debugPrint("Response from $ip: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['name'] == 'BioAMP') {
          setState(() {
            devices.add({'ip': ip, 'name': data['name']});
            scanLogs.add("✅ $ip responded: ${data['name']}");
            debugPrint("✅ $ip responded: ${data['name']}");

          });
        } else {
          scanLogs.add("🟡 $ip responded, but not BioAMP.");
          debugPrint("🟡 $ip responded, but not BioAMP.");
        }
      } else {
        scanLogs.add("❌ $ip responded with status ${response.statusCode}.");
        debugPrint("❌ $ip responded with status ${response.statusCode}.");
      }
    } catch (e) {
      scanLogs.add("❌ $ip failed (${e.runtimeType}).");
      debugPrint("❌ $ip failed (${e.runtimeType}).");
    }

    if (mounted && devices.length + 1 >= 254) {
      setState(() => isScanning = false);
    }
  }

  Future<List<String>> _getAllLocalIps() async {
    List<String> ips = [];
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          ips.add(addr.address);
        }
      }
    }
    return ips;
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
                  ? const Text('No BioAMP devices found.')
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
