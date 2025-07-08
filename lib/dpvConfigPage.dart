import 'dart:convert';
import 'package:bio_amp/voltDashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'analyteDashboard.dart';

class DPVConfigPage extends StatefulWidget {
  final String deviceIp;

  const DPVConfigPage({super.key, required this.deviceIp});

  @override
  State<DPVConfigPage> createState() => _DPVConfigPageState();
}

class _DPVConfigPageState extends State<DPVConfigPage> {
  final startVoltageCtrl = TextEditingController(text: "-1.0");
  final endVoltageCtrl = TextEditingController(text: "1.0");

  final stepHeightCtrl = TextEditingController(text: "0.01");
  final pulseHeightCtrl = TextEditingController(text: "0.05");
  final stepTimeCtrl = TextEditingController(text: "100");
  final pulseWidthCtrl = TextEditingController(text: "500");

  void _startDPV() async {
    debugPrint("Starting DPV with:");
    final config = {
      "mode": "DPV",
      "startVoltage": double.tryParse(startVoltageCtrl.text) ?? -0.5,
      "endVoltage": double.tryParse(endVoltageCtrl.text) ?? 1.0,
      "stepHeight": double.tryParse(stepHeightCtrl.text) ?? 0.1,
      "pulseHeight": double.tryParse(pulseHeightCtrl.text) ?? 0.05,
      "stepTime": int.tryParse(stepTimeCtrl.text) ?? 100,
      "pulseWidth": int.tryParse(pulseWidthCtrl.text) ?? 500,
    };

    try {
      final response = await http.post(
        Uri.parse("http://${widget.deviceIp}/dpv"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(config),
      );
      debugPrint("Config: $config");
      debugPrint("DPV Response: ${response.body}");
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoltDashboard(
              deviceIp: widget.deviceIp,
              mode: "DPV",
            ),
          ),
        );
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start DPV: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Differential Pulse Voltammetry")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField("Start Voltage (V) [-1.0 to 1.0]", startVoltageCtrl),
            _buildField("End Voltage (V) [-1.0 to 1.0]", endVoltageCtrl),
            _buildField("Step Height (V)", stepHeightCtrl),
            _buildField("Step Time (ms)", stepTimeCtrl),
            _buildField("Pulse Height (V)", pulseHeightCtrl),
            _buildField("Pulse Width (ms)", pulseWidthCtrl),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startDPV,
              icon: const Icon(Icons.send),
              label: const Text("Start DPV"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
