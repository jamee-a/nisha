import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({super.key});

  @override
  State<BluetoothConnectionPage> createState() => _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    // Check if Bluetooth is supported
    FlutterBluePlus.isSupported.then((supported) {
      if (!supported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth is not supported on this device')),
        );
      }
    });
  }

  Future<void> startScan() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning: $e')),
      );
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // await device.connect();
      debugPrint('data: $device');

      setState(() {
        connectedDevice = device;
      });
      if (mounted) {
        Navigator.of(context).pop(device); // Return the connected device
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting: $e')),
      );
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