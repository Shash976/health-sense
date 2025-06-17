import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AnalyteDashboard extends StatefulWidget {
  final String deviceIp;
  final String testName;
  final double min;
  final double max;

  const AnalyteDashboard({
    super.key,
    required this.deviceIp,
    required this.testName,
    required this.min,
    required this.max,
  });

  @override
  State<AnalyteDashboard> createState() => _AnalyteDashboardState();
}

class _AnalyteDashboardState extends State<AnalyteDashboard> {
  double? value;

  Future<void> _fetchValue() async {
    try {
      final url = Uri.parse('http://${widget.deviceIp}/result');
      final response = await http.get(url);
      debugPrint("Response: ${response.body}");
      if (response.statusCode == 200) {
        debugPrint("Response: ${response.body}");
        final data = json.decode(response.body);
        if (data.containsKey('value')) {
          setState(() {
            value = (data['value'] as num).toDouble();
          });
        } else if (data['status'] == 'processing') {
          // Retry after delay
          Future.delayed(const Duration(seconds: 2), _fetchValue);
        } else {
          debugPrint("Unexpected response: $data");
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch result: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchValue();
  }

  @override
  Widget build(BuildContext context) {
    final isNormal = value != null && value! >= widget.min && value! <= widget.max;

    return Scaffold(
      appBar: AppBar(title: Text("${widget.testName} Results")),
      body: value == null
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Fetching results..."),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.testName, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text("${value!.toStringAsFixed(2)} mg/dL", style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: ((value! - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0),
              color: isNormal ? Colors.green : Colors.red,
              backgroundColor: Colors.grey[300],
              minHeight: 10,
            ),
            const SizedBox(height: 12),
            Text(
              isNormal
                  ? 'Your ${widget.testName} level is normal.'
                  : 'Abnormal ${widget.testName} level.',
              style: TextStyle(
                color: isNormal ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Normal Range: ${widget.min} - ${widget.max} mg/dL"),
          ],
        ),
      ),
    );
  }
}
