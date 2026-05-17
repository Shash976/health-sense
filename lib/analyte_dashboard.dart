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
  String? _errorMessage;
  bool _cancelled = false;
  int _pollCount = 0;
  static const int _maxPolls = 150; // 5-minute cap at 2-second intervals

  Future<void> _fetchValue() async {
    if (_cancelled) return;
    if (_pollCount >= _maxPolls) {
      if (mounted) setState(() => _errorMessage = 'Timed out waiting for result.');
      return;
    }
    _pollCount++;
    try {
      final url = Uri.parse('http://${widget.deviceIp}/result');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (_cancelled || !mounted) return;
      debugPrint("Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('value')) {
          setState(() {
            value = (data['value'] as num).toDouble();
          });
        } else if (data['status'] == 'processing') {
          Future.delayed(const Duration(seconds: 2), () {
            if (!_cancelled) _fetchValue();
          });
        } else {
          setState(() => _errorMessage = 'Unexpected response from device.');
        }
      } else {
        setState(() => _errorMessage = 'Device returned status ${response.statusCode}.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Network error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchValue();
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
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
                if (_errorMessage != null) ...[
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ] else ...[
                  const Text("Fetching results..."),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
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
