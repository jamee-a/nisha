import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
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
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    // Check for Bluetooth connection when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isConnected) {
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

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        connectedDevice = result['device'] as BluetoothDevice?;
        _isConnected = result['connected'] as bool? ?? false;
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

    if (!_isConnected || connectedDevice == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.appTitle),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bluetooth_disabled,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No device connected',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please connect to a Bluetooth device to access health monitoring features',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _navigateToBluetoothConnection,
                icon: const Icon(Icons.bluetooth),
                label: const Text('Connect to Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
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
                _isConnected = false;
              });
              _navigateToBluetoothConnection();
            },
            tooltip: 'Reconnect Device',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connection status card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.bluetooth_connected,
                    color: Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connected to Device',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          connectedDevice?.name ?? 'Unknown Device',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _navigateToBluetoothConnection,
                    tooltip: 'Reconnect',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
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
