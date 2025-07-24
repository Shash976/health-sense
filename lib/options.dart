import 'package:bio_amp/amp_config_page.dart';
import 'package:bio_amp/cv_config_page.dart';
import 'package:bio_amp/dpv_config_page.dart';
import 'package:bio_amp/analyteTasks.dart';
import 'package:bio_amp/wifi_scan_page.dart';
import 'package:flutter/material.dart';

import 'analysis_page.dart';

class OptionsPage extends StatelessWidget {
  final String deviceIp;

  const OptionsPage({super.key, required this.deviceIp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Options'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(padding: EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskPage(
                        deviceIp: deviceIp
                      ),
                    ),
                  );
                },
                child: const Text('Analyte Mode'),
              ),
            ),
            Padding(padding: EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CVConfigPage(
                        deviceIp: deviceIp,
                      ),
                    ),
                  );
                },
                child: const Text('CV Mode'),
              ),
            ),
            Padding(padding: EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DPVConfigPage(deviceIp: deviceIp)
                    ),
                  );
                },
                child: const Text('DPV Mode'),
              ),
            ),
            Padding(padding: EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AMPConfigPage(
                          deviceIp: deviceIp
                      ),
                    ),
                  );
                },
                child: const Text('Amperometry Mode'),
              ),
            ),
            Padding(padding: EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalysisPage()
                    ),
                  );
                },
                child: const Text('Calibration'),
              ),
            ),
            Padding(padding: EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => WifiScanPage()
                    ),
                  );
                },
                child: const Text('Wi-Fi Scan'),
              ),
            ),
          ]
        )
      )
    );
  }
}