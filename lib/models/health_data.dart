import 'package:flutter/foundation.dart';

class HealthData extends ChangeNotifier {
  int? heartRate;
  int? oxygenLevel;
  double? temperature;

  HealthData({this.heartRate = 72, this.oxygenLevel = 98, this.temperature = 36.0});

  void updateHeartRate(int value) {
    heartRate = value;
    notifyListeners();
  }

  void updateOxygenLevel(int value) {
    oxygenLevel = value;
    notifyListeners();
  }

  void updateTemperature(double value) {
    temperature = value;
    notifyListeners();
  }

  void updateAll({int? heartRate, int? oxygenLevel, double? temperature}) {
    if (heartRate != null) this.heartRate = heartRate;
    if (oxygenLevel != null) this.oxygenLevel = oxygenLevel;
    if (temperature != null) this.temperature = temperature;
    notifyListeners();
  }
} 