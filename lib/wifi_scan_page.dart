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

class _WifiScanPageState extends State<WifiScanPage> {
  List<Map<String, String>> devices = [];
  bool isScanning = false;
  List<String> scanLogs = [];

  Future<List<String>> _getAllLocalIps() async {
    List<String> ips = [];
    try {
      // Only attempt on platforms where dart:io is supported and not web
      if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
        for (var interface in await NetworkInterface.list()) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              ips.add(addr.address);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to list network interfaces: $e');
    }
    return ips;
  }

  Future<List<String>> _getWifiOrHotspotIps() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.wifi) {
      final wifiIp = await NetworkUtils.getWifiIp();
      if (wifiIp != null) {
        // Check if it's a hotspot IP (commonly 192.168.43.x)
        final subnet = NetworkUtils.getHotspotSubnet(wifiIp);
        return [wifiIp];
      }
    }
    // Fallback: try to get all local IPs (legacy)
    return await _getAllLocalIps();
  }

  Future<void> _scanNetwork() async {
    setState(() {
      isScanning = true;
      devices = [];
      scanLogs = ["🔍 Starting scan..."];
    });

    final localIps = await _getWifiOrHotspotIps();
    if (localIps.isEmpty) {
      setState(() {
        isScanning = false;
        scanLogs.add("❌ Could not find any local IPs.");
      });
      return;
    }
    debugPrint("📡 Local IPs: $localIps");

    bool foundDevice = false;

    for (final localIp in localIps) {
      final subnet = NetworkUtils.getHotspotSubnet(localIp);
      debugPrint("📡 Scanning subnet: $subnet");
      List<Future<void>> futures = [];
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet$i';
        futures.add(_checkDevice(ip, (log, deviceFound) {
          debugPrint(log);
          if (deviceFound) foundDevice = true;
        }));
      }
      await Future.wait(futures);
    }
    if (mounted) {
      setState(() {
        isScanning = false;
        if (!foundDevice) scanLogs.add("🔎 Scan complete. No BioAMP devices found.");
        else scanLogs.add("✅ Scan complete.");
      });
    }
  }

  Future<void> _checkDevice(String ip, void Function(String, bool) logCallback) async {
    final url = Uri.parse('http://$ip/whoami');
    try {
      logCallback("➡️ Pinging $ip...", false);
      final response = await http.get(url).timeout(const Duration(milliseconds: 1000));
      logCallback("📡 Pinging $ip: ${response.statusCode}", true);
      if (response.statusCode == 200) {
        logCallback("📡 $ip responded: ${response.body}", true);
        final data = json.decode(response.body);
        if (data['name'] == 'BioAMP') {
          devices.add({'ip': ip, 'name': data['name']});
          logCallback("✅ $ip responded: ${data['name']}", true);
        } else {
          logCallback("🟡 $ip responded, but not BioAMP.", false);
        }
      } else {
        logCallback("❌ $ip responded with status ${response.statusCode}.", false);
      }
    } catch (e) {
      logCallback("❌ $ip failed (${e.runtimeType}).", false);
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
