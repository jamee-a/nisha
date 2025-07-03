import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/health_data.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSleepAnalysisCard(context),
          const SizedBox(height: 16),
          _buildSleepStatsGrid(context),
          const SizedBox(height: 16),
          _buildHistoricalReports(context),
        ],
      ),
    );
  }

  Widget _buildSleepAnalysisCard(BuildContext context) {
    final healthData = Provider.of<HealthData>(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.sleepAnalysis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  Icons.favorite,
                  AppLocalizations.of(context)!.heartRate,
                  healthData.heartRate != null ? '${healthData.heartRate} BPM' : '--',
                ),
                _buildStatItem(
                  context,
                  Icons.air,
                  AppLocalizations.of(context)!.oxygenLevel,
                  healthData.oxygenLevel != null ? '${healthData.oxygenLevel}%' : '--',
                ),
                _buildStatItem(
                  context,
                  Icons.thermostat,
                  'Temperature',
                  healthData.temperature != null ? '${healthData.temperature}°C' : '--',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  Widget _buildSleepStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildSleepStatCard(
          context,
          AppLocalizations.of(context)!.deepSleep,
          '2.5 ${AppLocalizations.of(context)!.hours}',
          Icons.nightlight_round,
        ),
        _buildSleepStatCard(
          context,
          AppLocalizations.of(context)!.lightSleep,
          '4.5 ${AppLocalizations.of(context)!.hours}',
          Icons.bedtime,
        ),
      ],
    );
  }

  Widget _buildSleepStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalReports(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.historicalReports,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.sleepDurationOverWeek,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Placeholder for sleep duration chart
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Sleep Duration Chart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
