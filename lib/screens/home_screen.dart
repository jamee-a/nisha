import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_connection_page.dart';

import 'dashboard_screen.dart';
import 'sleep_analysis_screen.dart';
import 'smart_alarm_screen.dart';
import 'settings_screen.dart';
import 'historical_reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    // Check for Bluetooth connection when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (connectedDevice == null) {
        _navigateToBluetoothConnection();
      }
    });
  }

  Future<void> _navigateToBluetoothConnection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BluetoothConnectionPage(),
      ),
    );

    if (result != null && result is BluetoothDevice) {
      setState(() {
        connectedDevice = result;
      });
    } else {
      // If no device was connected, show a message and try again
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please connect to a device to continue'),
            duration: Duration(seconds: 2),
          ),
        );
        _navigateToBluetoothConnection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (connectedDevice == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.appTitle),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No device connected'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateToBluetoothConnection,
                child: const Text('Connect to Device'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_connected),
            onPressed: () {
              setState(() {
                connectedDevice = null;
              });
              _navigateToBluetoothConnection();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMenuButton(
            context,
            label: localizations.dashboard,
            icon: Icons.bar_chart,
            destination: const DashboardScreen(),
          ),
          const SizedBox(height: 20),
          _buildMenuButton(
            context,
            label: localizations.sleepAnalysis,
            icon: Icons.analytics,
            destination: const SleepAnalysisScreen(),
          ),
          const SizedBox(height: 20),
          _buildMenuButton(
            context,
            label: localizations.smartAlarm,
            icon: Icons.alarm,
            destination: const SmartAlarmScreen(),
          ),
          const SizedBox(height: 20),
          _buildMenuButton(
            context,
            label: localizations.historicalReports,
            icon: Icons.bar_chart_rounded,
            destination: const HistoricalReportsScreen(),
          ),
          const SizedBox(height: 20),
          _buildMenuButton(
            context,
            label: localizations.settings,
            icon: Icons.settings,
            destination: const SettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context,
      {required String label,
      required IconData icon,
      required Widget destination}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      },
    );
  }
}
