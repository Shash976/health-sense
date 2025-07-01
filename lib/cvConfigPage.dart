import 'dart:convert';
import 'package:bio_amp/analyteDashboard.dart';
import 'package:bio_amp/cvDashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'analyteDashboard.dart';

class RangeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text == '-' || text == '' || text == '.' || text == '-.') return newValue;
    final value = double.tryParse(text);
    if (value == null) return oldValue;
    if (value < -1.0 || value > 1.0) return oldValue;
    return newValue;
  }
}

class CVConfigPage extends StatefulWidget {
  final String deviceIp;

  const CVConfigPage({super.key, required this.deviceIp});

  @override
  State<CVConfigPage> createState() => _CVConfigPageState();
}

class _CVConfigPageState extends State<CVConfigPage> {
  final startVoltageCtrl = TextEditingController(text: "0.0");
  final endVoltageCtrl = TextEditingController(text: "1.0");
  final scanRateCtrl = TextEditingController(text: "100");
  final cyclesCtrl = TextEditingController(text: "3");

  void _startCV() async {
    debugPrint("Starting CV with:");
    final config = {
      "mode": "cv",
      "startVoltage": double.tryParse(startVoltageCtrl.text) ?? 0.0,
      "endVoltage": double.tryParse(endVoltageCtrl.text) ?? 1.0,
      "scanRate": double.tryParse(scanRateCtrl.text) ?? 1.0,
      "cycles": int.tryParse(cyclesCtrl.text) ?? 3,
    };

    try {
      final response = await http.post(
        Uri.parse("http://${widget.deviceIp}/cv"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(config),
      );
      debugPrint("Config: $config");
      debugPrint("CV Response: ${response.body}");
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CVDashboard(
              deviceIp: widget.deviceIp,
            ),
          ),
        );
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start CV: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cyclic Voltammetry")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField(
                "Start Voltage (V) (Enter between -1.0 to 1.0)",
                startVoltageCtrl,
                signed: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
                  RangeInputFormatter(),
                ]
            ),
            _buildField(
                "End Voltage (V) (Enter between -1.0 to 1.0)",
                endVoltageCtrl,
                signed: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
                  RangeInputFormatter(),
              ]
            ),
            _buildField("Scan Rate (V/s)", scanRateCtrl),
            _buildField("Cycle Count", cyclesCtrl),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startCV,
              icon: const Icon(Icons.send),
              label: const Text("Start CV"),
            )
          ],
        ),
      ),
    );
  }




  Widget _buildField(String label, TextEditingController controller, {bool decimal = true, bool signed = false, List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal, signed: signed),
        inputFormatters: inputFormatters,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
