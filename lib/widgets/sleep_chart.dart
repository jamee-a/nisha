import 'package:flutter/material.dart';
import '../models/sleep_data.dart';

class SleepChart extends StatelessWidget {
  final List<SleepData> sleepData;

  SleepChart({required this.sleepData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sleepData.map((data) {
        final hours = data.sleepDuration.inHours.toDouble();
        return ListTile(
          title: Text("${data.date.toLocal().toString().split(' ')[0]}"),
          subtitle: LinearProgressIndicator(
            value: hours / 12,
            backgroundColor: Colors.grey.shade300,
            color: Colors.deepPurple,
          ),
          trailing: Text("${hours.toStringAsFixed(1)} ساعة"),
        );
      }).toList(),
    );
  }
}
