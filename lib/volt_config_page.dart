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

class VoltConfigPage extends StatefulWidget {
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

  @override
  State<VoltConfigPage> createState() => _VoltConfigPageState();
}

class _VoltConfigPageState extends State<VoltConfigPage> {
  bool _loading = false;

  bool _validate() {
    for (final f in widget.fields) {
      final text = f.controller.text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${f.label} cannot be empty.')),
        );
        return false;
      }
      // Attempt to parse — accept both int and double
      if (double.tryParse(text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${f.label} must be a valid number.')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _start() async {
    if (_loading) return;
    if (!_validate()) return;

    setState(() => _loading = true);
    final config = widget.buildConfig(widget.fields);
    try {
      final response = await http
          .post(
            Uri.parse("http://${widget.deviceIp}/${widget.endpoint}"),
            headers: {"Content-Type": "application/json"},
            body: json.encode(config),
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoltDashboard(
              deviceIp: widget.deviceIp,
              mode: widget.mode,
            ),
          ),
        );
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to start ${widget.mode}: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final field in widget.fields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...widget.fields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: f.controller,
                keyboardType: f.keyboardType,
                inputFormatters: f.inputFormatters,
                enabled: !_loading,
                decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
              ),
            )),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : _start,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_loading ? "Starting..." : "Start ${widget.mode}"),
            ),
          ],
        ),
      ),
    );
  }
}
