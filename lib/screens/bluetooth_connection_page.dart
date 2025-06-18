import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({super.key});

  @override
  State<BluetoothConnectionPage> createState() => _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  bool isBluetoothOn = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
  }

  Future<void> _checkBluetoothState() async {
    // Check if Bluetooth is supported
    if (!await FlutterBluePlus.isSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth is not supported on this device')),
        );
      }
      return;
    }

    // Request permissions
    await _requestPermissions();

    // Listen to Bluetooth state changes
    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        isBluetoothOn = state == BluetoothAdapterState.on;
      });
      if (state == BluetoothAdapterState.off) {
        _showEnableBluetoothDialog();
      }
    });
  }

  Future<void> _requestPermissions() async {
    // Request location permission (required for Bluetooth scanning on Android)
    await Permission.location.request();

    // Request Bluetooth permissions for Android 12 and above
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      // Permissions granted
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permissions are required to scan for devices'),
          ),
        );
      }
    }
  }

  void _showEnableBluetoothDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bluetooth Required'),
        content: const Text('Please enable Bluetooth to scan for devices'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FlutterBluePlus.turnOn();
            },
            child: const Text('Enable Bluetooth'),
          ),
        ],
      ),
    );
  }

  Future<void> startScan() async {
    if (!isBluetoothOn) {
      _showEnableBluetoothDialog();
      return;
    }

    // Check permissions before scanning
    if (!await Permission.bluetoothScan.isGranted ||
        !await Permission.bluetoothConnect.isGranted ||
        !await Permission.location.isGranted) {
      await _requestPermissions();
      return;
    }

    setState(() {
      scanResults = [];
      isScanning = true;
    });

    try {
      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      
      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
        });
      });

      // Wait for scan to complete
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
      });
      if (mounted) {
        Navigator.of(context).pop(device);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Device'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          if (!isBluetoothOn)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red[100],
              child: const Row(
                children: [
                  Icon(Icons.bluetooth_disabled, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Bluetooth is turned off'),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isScanning ? null : startScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isScanning ? 'Scanning...' : 'Scan for Devices',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      result.device.platformName.isNotEmpty 
                        ? result.device.platformName 
                        : 'Unknown Device',
                      style: const TextStyle(fontSize: 16),
                    ),
                    subtitle: Text(
                      result.device.remoteId.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => connectToDevice(result.device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Connect'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 