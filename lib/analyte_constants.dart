import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Analyte {
  final String name;
  final String code;
  late final double oxidationPotential;
  late final double normalMinMGDL;
  late final double normalMaxMGDL;
  late final double conversionFactor;
  late final int time;
  late final double calibSlope;
  late final double calibConstant;

  Analyte(this.name, this.code, this.oxidationPotential, this.normalMinMGDL,
      this.normalMaxMGDL, this.conversionFactor, this.time, this.calibSlope,
      this.calibConstant)
      : assert(normalMinMGDL < normalMaxMGDL,
            'Normal minimum must be less than maximum');

  @override
  String toString() {
    return '$name (EP: $oxidationPotential, Normal Range: $normalMinMGDL - $normalMaxMGDL mg/dL, Conversion Factor: $conversionFactor)';
  }

  String get normalRange => '$normalMinMGDL - $normalMaxMGDL mg/dL';

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'oxidationPotential': oxidationPotential,
        'normalMinMGDL': normalMinMGDL,
        'normalMaxMGDL': normalMaxMGDL,
        'conversionFactor': conversionFactor,
        'time': time,
        'calibSlope': calibSlope,
        'calibConstant': calibConstant,
      };

  factory Analyte.fromJson(Map<String, dynamic> j) => Analyte(
        j['name'] as String,
        j['code'] as String,
        (j['oxidationPotential'] as num).toDouble(),
        (j['normalMinMGDL'] as num).toDouble(),
        (j['normalMaxMGDL'] as num).toDouble(),
        (j['conversionFactor'] as num).toDouble(),
        (j['time'] as num).toInt(),
        (j['calibSlope'] as num).toDouble(),
        (j['calibConstant'] as num).toDouble(),
      );
}

const _kAnalytesKey = 'analytes_v1';

// Defaults are always present as the baseline; user additions are appended.
final List<Analyte> _defaultAnalytes = [
  Analyte("Bilirubin", "BIL", 0.15, 0.1, 1.2, 17.1, 1000, 9.2609e-9, 7.276e-7),
  Analyte("ALP", "ALP", 0.25, 44, 147, 0, 800, 9.2609e-9, 7.276e-7),
  Analyte("ALT", "ALT", 0.30, 7, 56, 0, 1200, 9.2609e-9, 7.276e-7),
];

List<Analyte> analytes = List.of(_defaultAnalytes);

/// Call once at app startup (before runApp) to restore user-added analytes.
Future<void> loadAnalytes() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAnalytesKey);
    if (raw != null) {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      analytes = list
          .map((e) => Analyte.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  } catch (e) {
    debugPrint('loadAnalytes failed, falling back to defaults: $e');
    analytes = List.of(_defaultAnalytes);
  }
}

/// Persist the current analyte list. Call after any mutation.
Future<void> saveAnalytes() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kAnalytesKey, jsonEncode(analytes.map((a) => a.toJson()).toList()));
  } catch (e) {
    debugPrint('saveAnalytes failed: $e');
  }
}

void updateAnalyte(String name, String parameter, double newValue) {
  for (var analyte in analytes) {
    if (analyte.name == name) {
      switch (parameter) {
        case 'oxidationPotential':
          analyte.oxidationPotential = newValue;
        case 'normalMinMGDL':
          analyte.normalMinMGDL = newValue;
        case 'normalMaxMGDL':
          analyte.normalMaxMGDL = newValue;
        case 'conversionFactor':
          analyte.conversionFactor = newValue;
        case 'time':
          analyte.time = newValue.toInt();
        case 'calibSlope':
          analyte.calibSlope = newValue;
        case 'calibConstant':
          analyte.calibConstant = newValue;
        default:
          throw ArgumentError('Invalid parameter: $parameter');
      }
      saveAnalytes();
      return;
    }
  }
  throw ArgumentError('Analyte not found: $name');
}

void addAnalyte(Analyte analyte) {
  analytes.add(analyte);
  saveAnalytes();
}

Map<String, dynamic> serializeAnalyte(Analyte analyte) => analyte.toJson();

List<Map<String, dynamic>> serializeAnalytes() =>
    analytes.map((a) => a.toJson()).toList();
