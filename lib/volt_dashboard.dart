import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VoltDashboard extends StatefulWidget {
  final String deviceIp;
  final String mode;

  const VoltDashboard({super.key, required this.deviceIp, required this.mode});

  @override
  State<VoltDashboard> createState() => _VoltDashboardState();
}

class _VoltDashboardState extends State<VoltDashboard> {
  List<double> xValues = [];
  List<double> yValues = [];
  Timer? pollTimer;
  late ScrollController _scrollController;
  bool _autoScroll = true;
  bool _polling = false; // guard against concurrent in-flight requests
  bool _cancelled = false; // set in dispose so stale futures can self-abort

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    pollTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => fetchPoint(),
    );
  }

  Future<void> fetchPoint() async {
    if (_cancelled || _polling) return;
    _polling = true;
    try {
      final url = Uri.parse(
        "http://${widget.deviceIp}/${widget.mode.toLowerCase()}data",
      );
      final response = await http.get(url);
      if (_cancelled) return;
      debugPrint("${widget.mode.toUpperCase()} Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey("x") && data.containsKey("y")) {
          if (mounted) {
            setState(() {
              xValues.add((data["x"] as num).toDouble());
              yValues.add((data["y"] as num).toDouble());
            });
            if (_autoScroll) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_cancelled && _scrollController.hasClients && mounted) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          }
        } else if (data["status"] == "${widget.mode.toLowerCase()}_done") {
          pollTimer?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${widget.mode.toUpperCase()} measurement complete — ${xValues.length} points collected.")),
            );
          }
        }
      }
    } on SocketException {
      debugPrint(
        "Network error while fetching ${widget.mode.toUpperCase()} data.",
      );
    } catch (e) {
      debugPrint("Error polling ${widget.mode.toUpperCase()}: $e");
    } finally {
      _polling = false;
    }
  }

  void _downloadCSV() async {
    final isCV = widget.mode.toLowerCase() == "cv";
    String fileName;
    double? concentration;

    if (isCV) {
      concentration = await showDialog<double>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text("Enter Concentration"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: "e.g. 0.1 or 5.2"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  final value = double.tryParse(
                    controller.text.replaceAll(',', '.'),
                  );
                  if (value != null) {
                    Navigator.of(context).pop(value);
                  }
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

      if (concentration == null) {
        // User cancelled
        return;
      }
      final concStr = concentration.toString().replaceAll('.', '_');
      fileName = "cv_data_$concStr.csv";
    } else {
      fileName = "${widget.mode.toLowerCase()}_data.csv";
    }

    final csvLines = <String>[isCV ? "x,y,cycle" : "x,y"];
    if (isCV && xValues.isNotEmpty) {
      // Detect cycles via direction reversal: every 2 x-direction reversals = 1 complete cycle.
      int cycle = 1;
      int halfCycles = 0;
      for (int i = 0; i < xValues.length; i++) {
        if (i >= 2) {
          final double prev = xValues[i - 1] - xValues[i - 2];
          final double curr = xValues[i] - xValues[i - 1];
          // A sign change in consecutive deltas means the sweep reversed direction.
          if (prev.abs() > 1e-10 && curr.abs() > 1e-10 && prev * curr < 0) {
            halfCycles++;
            if (halfCycles % 2 == 0) cycle++; // forward+back = one full cycle
          }
        }
        csvLines.add("${xValues[i]},${yValues[i]},$cycle");
      }
    } else {
      for (int i = 0; i < xValues.length; i++) {
        csvLines.add("${xValues[i]},${yValues[i]}");
      }
    }
        final csv = csvLines.join("\n");

    final Directory directory =
        (await getDownloadsDirectory()) ?? await getApplicationDocumentsDirectory();

    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    final filePath = "${directory.path}/$fileName";
    final file = File(filePath);
    await file.writeAsString(csv);

    // Ensure you have `import 'package:flutter_downloader/flutter_downloader.dart';`
    // Enqueue a task so the Download manager/notification is used
    try {
      await FlutterDownloader.enqueue(
        url: 'file://$filePath',
        savedDir: directory.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );
    } catch (e) {
      debugPrint('FlutterDownloader enqueue failed: $e');
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("CSV saved to: $filePath")));
  }

  @override
  void dispose() {
    _cancelled = true;
    pollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle = "${widget.mode.toUpperCase()} Data Stream";
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Received ${xValues.length} points"),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Autoscroll"),
                Switch(
                  value: _autoScroll,
                  onChanged: (value) {
                    setState(() {
                      _autoScroll = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: xValues.length,
                itemBuilder: (context, index) {
                  return Text(
                    "(${xValues[index].toStringAsFixed(3)}, ${yValues[index].toStringAsFixed(3)})",
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: xValues.isEmpty ? null : _downloadCSV,
              icon: const Icon(Icons.download),
              label: const Text("Download CSV"),
            ),
          ],
        ),
      ),
    );
  }
}
