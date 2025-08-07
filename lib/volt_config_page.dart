import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:health_sense/volt_dashboard.dart';

class VoltConfigField {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  VoltConfigField({
    required this.label,
    required this.controller,
    this.inputFormatters,
    TextInputType? keyboardType,
  }) : keyboardType = keyboardType ?? const TextInputType.numberWithOptions(decimal: true);
}

class VoltConfigPage extends StatelessWidget {
  final String deviceIp;
  final String title;
  final String endpoint;
  final String mode;
  final List<VoltConfigField> fields;
  final Map<String, dynamic> Function(List<VoltConfigField>) buildConfig;

  const VoltConfigPage({
    super.key,
    required this.deviceIp,
    required this.title,
    required this.endpoint,
    required this.mode,
    required this.fields,
    required this.buildConfig,
  });

  void _start(BuildContext context) async {
    final config = buildConfig(fields);
    try {
      final response = await http.post(
        Uri.parse("http://$deviceIp/$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(config),
      );
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoltDashboard(
              deviceIp: deviceIp,
              mode: mode,
            ),
          ),
        );
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start $mode: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...fields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: f.controller,
                keyboardType: f.keyboardType,
                inputFormatters: f.inputFormatters,
                decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
              ),
            )),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _start(context),
              icon: const Icon(Icons.send),
              label: Text("Start $mode"),
            )
          ],
        ),
      ),
    );
  }
}
