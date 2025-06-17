class Analyte {
  final String name;
  final String code;
  late final double oxidationPotential;
  late final double normalMinMGDL;
  late final double normalMaxMGDL;
  late final double conversionFactor;
  late final int time;
  late final double min;
  late final double max;

  Analyte(this.name, this.code, this.oxidationPotential, this.normalMinMGDL, this.normalMaxMGDL, this.conversionFactor, this.time, this.min, this.max)
      : assert(normalMinMGDL < normalMaxMGDL, 'Normal minimum must be less than maximum');

  @override
  String toString() {
    return '$name (EP: $oxidationPotential, Normal Range: $normalMinMGDL - $normalMaxMGDL mg/dL, Conversion Factor: $conversionFactor)';
  }
  String get normalRange => '$normalMinMGDL - $normalMaxMGDL mg/dL';
}

List<Analyte> analytes = [
  Analyte("Bilirubin", "BIL", 0.15, 0.1, 1.2, 17.1, 1000, 1.0, 5.2),  // 1000 ms for Bilirubin
  Analyte("ALP", "ALP",       0.25, 44, 147, 0, 800, 2, 4),       // 800 ms for ALP
  Analyte("ALT", "ALT",      0.30, 7, 56, 0, 1200, 5, 30),        // 1200 ms for ALT
];

void updateAnalyte(String name, String parameter, double newValue){
  for (var analyte in analytes) {
    if (analyte.name == name) {
      switch (parameter) {
        case 'oxidationPotential':
          analyte.oxidationPotential = newValue;
          break;
        case 'normalMinMGDL':
          analyte.normalMinMGDL = newValue;
          break;
        case 'normalMaxMGDL':
          analyte.normalMaxMGDL = newValue;
          break;
        case 'conversionFactor':
          analyte.conversionFactor = newValue;
          break;
        case 'time':
          analyte.time = newValue.toInt();
          break;
        default:
          throw ArgumentError('Invalid parameter: $parameter');
      }
      return;
    }
  }
  throw ArgumentError('Analyte not found: $name');
}

void addAnalyte(Analyte analyte) {
  analytes.add(analyte);
}

Map<String, dynamic> serializeAnalyte(Analyte analyte) {
  return {
    'name': analyte.name,
    'code': analyte.code,
    'oxidationPotential': analyte.oxidationPotential,
    'normalMinMGDL': analyte.normalMinMGDL,
    'normalMaxMGDL': analyte.normalMaxMGDL,
    'conversionFactor': analyte.conversionFactor,
    'time': analyte.time,
  };
}

List<Map<String, dynamic>> serializeAnalytes(){
  List<Map<String, dynamic>> serialized = analytes.map((a) {
    return {
      'name': a.name,
      'code': a.code,
      'oxidationPotential': a.oxidationPotential,
      'normalMinMGDL': a.normalMinMGDL,
      'normalMaxMGDL': a.normalMaxMGDL,
      'conversionFactor': a.conversionFactor,
      'time': a.time,
    };
  }).toList();
  return serialized;
}