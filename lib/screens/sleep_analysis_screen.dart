import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SleepAnalysisScreen extends StatelessWidget {
  const SleepAnalysisScreen({Key? key}) : super(key: key);

  final double heartRate = 72; // bpm
  final double oxygenLevel = 96; // %
  final double deepSleepHours = 2.5; // hours
  final double lightSleepHours = 4.0;

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(local.sleepAnalysis),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildCard(
                context, local.heartRate, '$heartRate bpm', Icons.favorite),
            _buildCard(context, local.oxygenLevel, '$oxygenLevel%', Icons.air),
            _buildCard(context, local.deepSleep,
                '$deepSleepHours ${local.hours}', Icons.bedtime),
            _buildCard(context, local.lightSleep,
                '$lightSleepHours ${local.hours}', Icons.bed),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}
