import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class RegressionResult {
  final double slope;
  final double intercept;
  final double r2;
  RegressionResult(
      {required this.slope, required this.intercept, required this.r2});
}

RegressionResult? calculateLinearRegression(Map<double, double> data) {
  if (data.length < 2) return null;
  final x = data.keys.toList();
  final y = data.values.toList();
  final n = x.length;
  final meanX = x.reduce((a, b) => a + b) / n;
  final meanY = y.reduce((a, b) => a + b) / n;
  double numerator = 0;
  double denominator = 0;
  for (int i = 0; i < n; i++) {
    numerator += (x[i] - meanX) * (y[i] - meanY);
    denominator += pow(x[i] - meanX, 2).toDouble();
  }
  final slope = numerator / denominator;
  final intercept = meanY - slope * meanX;
  double ssTot = 0;
  double ssRes = 0;
  for (int i = 0; i < n; i++) {
    final yPred = slope * x[i] + intercept;
    ssTot += pow(y[i] - meanY, 2).toDouble();
    ssRes += pow(y[i] - yPred, 2).toDouble();
  }
  final r2 = 1 - (ssRes / ssTot);
  return RegressionResult(slope: slope, intercept: intercept, r2: r2);
}

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  double? voltage;
  int? cycle;
  SplayTreeMap<double, double> concentrationToCurrent = SplayTreeMap();
  bool isLoading = false;
  String? errorMessage;
  RegressionResult? regressionResult;

  final voltageController = TextEditingController();
  final cycleController = TextEditingController();
  final GlobalKey chartKey = GlobalKey();

  Future<void> pickAndAnalyzeFiles() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
      concentrationToCurrent.clear();
      regressionResult = null;
    });
    try {
      if (voltage == null || cycle == null) {
        setState(() {
          errorMessage = 'Please enter valid voltage and cycle values.';
          isLoading = false;
        });
        return;
      }
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      for (var file in result.files) {
        if (file.path == null) continue;
        final filename = file.name;
        final match = RegExp(r'cv_data_(\d+_\d+)\.csv').firstMatch(filename);
        if (match == null) continue;
        final concentrationStr = match.group(1)!.replaceAll('_', '.');
        final concentration = double.tryParse(concentrationStr);
        if (concentration == null) continue;
        try {
          final csvContent = await File(file.path!).readAsString();
          final lines = LineSplitter.split(csvContent);
          for (var line in lines) {
            final parts = line.split(',');
            if (parts.length < 3) continue;
            final x = double.tryParse(parts[0]);
            final y = double.tryParse(parts[1]);
            final cyc = int.tryParse(parts[2]);
            if (x == null || y == null || cyc == null) continue;
            if (x == voltage && cyc == cycle) {
              concentrationToCurrent[concentration] = y;
              break;
            }
          }
        } catch (e) {
          setState(() {
            errorMessage = 'Error reading file: \'${file.name}\'';
          });
        }
      }
      if (concentrationToCurrent.isEmpty && errorMessage == null) {
        setState(() {
          errorMessage = 'No matching data found.';
          regressionResult = null;
        });
      } else {
        setState(() {
          regressionResult = calculateLinearRegression(concentrationToCurrent);
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred during analysis.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveChartAsJpg() async {
    try {
      RenderRepaintBoundary boundary = chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image chartImage = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await chartImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();
      final decoded = img.decodeImage(pngBytes);
      if (decoded == null) return; //
      final jpg = img.encodeJpg(decoded);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/concentration_current_chart.jpg';
      final file = File(filePath);
      await file.writeAsBytes(jpg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chart saved to $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save chart.')),
        );
      }
    }
  }

  @override
  void dispose() {
    voltageController.dispose();
    cycleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analysis Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: voltageController,
              decoration: InputDecoration(labelText: 'Voltage'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => setState(() {
                voltage = double.tryParse(val);
              }),
            ),
            TextField(
              controller: cycleController,
              decoration: InputDecoration(labelText: 'Cycle Number'),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() {
                cycle = int.tryParse(val);
              }),
            ),
            if (errorMessage != null) ...[
              SizedBox(height: 8),
              Text(errorMessage!, style: TextStyle(color: Colors.red)),
            ],
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: (voltage != null && cycle != null && !isLoading)
                  ? pickAndAnalyzeFiles
                  : null,
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Upload CSV Files'),
            ),
            SizedBox(height: 24),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : concentrationToCurrent.isEmpty
                      ? Center(
                          child: Text(
                              errorMessage ?? 'No results to display.'))
                      : Column(
                          children: [
                            RepaintBoundary(
                              key: chartKey,
                              child: SizedBox(
                                height: 250,
                                child: LineChart(
                                  LineChartData(
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: true),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: true),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: true),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: concentrationToCurrent.entries
                                            .map((e) => FlSpot(e.key, e.value))
                                            .toList(),
                                        isCurved: false,
                                        barWidth: 2,
                                        color: Colors.blue,
                                        dotData: FlDotData(show: true),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (regressionResult != null) ...[
                              SizedBox(height: 16),
                              Text('Slope: ${regressionResult!.slope.toStringAsFixed(4)}'),
                              Text('Intercept: ${regressionResult!.intercept.toStringAsFixed(4)}'),
                              Text('R² score: ${regressionResult!.r2.toStringAsFixed(4)}'),
                              SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: saveChartAsJpg,
                                icon: Icon(Icons.save_alt),
                                label: Text('Save as JPG'),
                              ),
                            ],
                            SizedBox(height: 16),
                            Expanded(
                              child: ListView(
                                children: concentrationToCurrent.entries
                                    .map((e) => ListTile(
                                          title: Text('Concentration: ${e.key}'),
                                          subtitle: Text('Current: ${e.value}'),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}