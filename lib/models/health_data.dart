import 'package:flutter/foundation.dart';

class HealthData extends ChangeNotifier {
  int? heartRate;
  int? oxygenLevel;
  double? temperature;
  DateTime? lastUpdate;

  HealthData({this.heartRate = 72, this.oxygenLevel = 98, this.temperature = 36.0});

  void updateHeartRate(int value) {
    heartRate = value;
    lastUpdate = DateTime.now();
    notifyListeners();
  }

  void updateOxygenLevel(int value) {
    oxygenLevel = value;
    lastUpdate = DateTime.now();
    notifyListeners();
  }

  void updateTemperature(double value) {
    temperature = value;
    lastUpdate = DateTime.now();
    notifyListeners();
  }

  void updateAll({int? heartRate, int? oxygenLevel, double? temperature}) {
    if (heartRate != null) this.heartRate = heartRate;
    if (oxygenLevel != null) this.oxygenLevel = oxygenLevel;
    if (temperature != null) this.temperature = temperature;
    lastUpdate = DateTime.now();
    notifyListeners();
  }

  // Parse data from Bluetooth device
  void parseBluetoothData(String data) {
    try {
      // Remove any null characters or control characters
      final cleanData = data.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      
      if (cleanData.isEmpty) return;

      debugPrint('📥 Parsing health data: $cleanData');

      // Try different data formats
      
      // Format 1: JSON {"hr": 75, "spo2": 98, "temp": 36.5}
      if (cleanData.startsWith('{') && cleanData.endsWith('}')) {
        _parseJsonData(cleanData);
        return;
      }

      // Format 2: CSV "HR,75,SPO2,98,TEMP,36.5"
      if (cleanData.contains(',') && cleanData.contains('HR')) {
        _parseCsvData(cleanData);
        return;
      }

      // Format 3: Simple format "HR:75 SPO2:98 TEMP:36.5"
      if (cleanData.contains('HR:') || cleanData.contains('SPO2:') || cleanData.contains('TEMP:')) {
        _parseSimpleFormat(cleanData);
        return;
      }

      // Format 4: Just numbers "75,98,36.5" (HR, SPO2, TEMP)
      if (RegExp(r'^\d+,\d+,\d+\.?\d*$').hasMatch(cleanData)) {
        _parseNumberFormat(cleanData);
        return;
      }

      debugPrint('📥 Unknown data format: $cleanData');
      
    } catch (e) {
      debugPrint('📥 Error parsing health data: $e');
    }
  }

  void _parseJsonData(String jsonData) {
    try {
      // Simple JSON parsing (you can use dart:convert for more complex JSON)
      if (jsonData.contains('"hr"') || jsonData.contains('"heartRate"')) {
        final hrMatch = RegExp(r'"hr"?\s*:\s*(\d+)').firstMatch(jsonData);
        if (hrMatch != null) {
          updateHeartRate(int.parse(hrMatch.group(1)!));
        }
      }
      
      if (jsonData.contains('"spo2"') || jsonData.contains('"oxygen"')) {
        final spo2Match = RegExp(r'"spo2"?\s*:\s*(\d+)').firstMatch(jsonData);
        if (spo2Match != null) {
          updateOxygenLevel(int.parse(spo2Match.group(1)!));
        }
      }
      
      if (jsonData.contains('"temp"') || jsonData.contains('"temperature"')) {
        final tempMatch = RegExp(r'"temp"?\s*:\s*(\d+\.?\d*)').firstMatch(jsonData);
        if (tempMatch != null) {
          updateTemperature(double.parse(tempMatch.group(1)!));
        }
      }
    } catch (e) {
      debugPrint('📥 Error parsing JSON: $e');
    }
  }

  void _parseCsvData(String csvData) {
    try {
      final parts = csvData.split(',');
      for (int i = 0; i < parts.length - 1; i += 2) {
        final key = parts[i].trim().toUpperCase();
        final value = parts[i + 1].trim();
        
        switch (key) {
          case 'HR':
            updateHeartRate(int.parse(value));
            break;
          case 'SPO2':
            updateOxygenLevel(int.parse(value));
            break;
          case 'TEMP':
            updateTemperature(double.parse(value));
            break;
        }
      }
    } catch (e) {
      debugPrint('📥 Error parsing CSV: $e');
    }
  }

  void _parseSimpleFormat(String data) {
    try {
      // Extract HR
      final hrMatch = RegExp(r'HR:(\d+)').firstMatch(data);
      if (hrMatch != null) {
        updateHeartRate(int.parse(hrMatch.group(1)!));
      }
      
      // Extract SPO2
      final spo2Match = RegExp(r'SPO2:(\d+)').firstMatch(data);
      if (spo2Match != null) {
        updateOxygenLevel(int.parse(spo2Match.group(1)!));
      }
      
      // Extract TEMP
      final tempMatch = RegExp(r'TEMP:(\d+\.?\d*)').firstMatch(data);
      if (tempMatch != null) {
        updateTemperature(double.parse(tempMatch.group(1)!));
      }
    } catch (e) {
      debugPrint('📥 Error parsing simple format: $e');
    }
  }

  void _parseNumberFormat(String data) {
    try {
      final parts = data.split(',');
      if (parts.length >= 3) {
        updateHeartRate(int.parse(parts[0]));
        updateOxygenLevel(int.parse(parts[1]));
        updateTemperature(double.parse(parts[2]));
      }
    } catch (e) {
      debugPrint('📥 Error parsing number format: $e');
    }
  }
} 