import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'analyteDashboard.dart';
import 'ampDashboard.dart';

class AMPConfigPage extends StatefulWidget {
  final String deviceIp;

  const AMPConfigPage({super.key, required this.deviceIp});

  @override
  State<AMPConfigPage> createState() => _AMPConfigPageState();
}

class _AMPConfigPageState extends State<AMPConfigPage> {
  final oxidationPotentialCtrl = TextEditingController(text: "0.0");
  final runTimeCtrl = TextEditingController(text: "100");
  final measureIntervalCtrl = TextEditingController(text: "100");
  final pulseHeightCtrl = TextEditingController(text: "100");
  final stepTimeCtrl = TextEditingController(text: "100");
  final pulseWidthCtrl = TextEditingController(text: "3");

  void _startAMP() async {
    debugPrint("Starting AMP with:");
    final config = {
      "mode": "AMP",
      "oxidationPotential": double.tryParse(oxidationPotentialCtrl.text) ?? 0.0,
      "runTime": int.tryParse(runTimeCtrl.text) ?? 12,
      "measureInterval": int.tryParse(measureIntervalCtrl.text) ?? 120,
    };

    try {
      final response = await http.post(
        Uri.parse("http://${widget.deviceIp}/amp"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(config),
      );
      debugPrint("Config: $config");
      debugPrint("AMP Response: ${response.body}");
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AMPDashboard(
              deviceIp: widget.deviceIp,
            ),
          ),
        );
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start AMP: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Amperometric Titration")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField("Oxidation Potential (V)", oxidationPotentialCtrl),
            _buildField("Run Time (s)", runTimeCtrl),
            _buildField("Measure Interval (s)", measureIntervalCtrl),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startAMP,
              icon: const Icon(Icons.send),
              label: const Text("Start AMP"),
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
