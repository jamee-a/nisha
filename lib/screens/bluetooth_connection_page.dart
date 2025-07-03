import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({Key? key}) : super(key: key);

  @override
  State<BluetoothConnectionPage> createState() =>
      _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  final List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _notifyChar;   // first NOTIFY characteristic we find
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _requestPermissions();   // ask once at start
    _checkBluetoothState(); // check bluetooth state on init
    
    // Test toast on page load
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _showToast('Bluetooth page loaded successfully!', isError: false);
      }
    });
  }

  /* ──────────── Bluetooth State Check ──────────── */
  Future<void> _checkBluetoothState() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.off) {
        _showToast('Bluetooth must be turned on to scan for devices', isError: true);
      }
    } catch (e) {
      _showToast('Failed to check Bluetooth state: $e', isError: true);
    }
  }

  /* ──────────── Toast Notifications ──────────── */
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    
    debugPrint('Showing toast: $message (isError: $isError)');
    
    // Try multiple approaches to show the toast
    try {
      // Method 1: Using ScaffoldMessenger.of(context)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error : Icons.info,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      debugPrint('Failed to show toast with ScaffoldMessenger: $e');
      
      // Method 2: Simple debug print as fallback
      debugPrint('TOAST: $message');
    }
  }

  /* ──────────── Permissions ──────────── */
  Future<void> _requestPermissions() async {
    try {
      final results = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,      // required by Android for BLE scan
      ].request();
      
      // Check if any permission was denied
      for (final result in results.entries) {
        if (result.value.isDenied) {
          _showToast('${result.key.toString().split('.').last} permission is required', isError: true);
        }
      }
    } catch (e) {
      _showToast('Failed to request permissions: $e', isError: true);
    }
  }

  /* ──────────── Scanning ──────────── */
  Future<void> _startScan() async {
    try {
      // Check Bluetooth state before scanning
      final state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.off) {
        _showToast('Bluetooth must be turned on to scan for devices', isError: true);
        return;
      }

      setState(() {
        _scanResults.clear();
        _isScanning = true;
      });

      _showToast('Starting scan for Bluetooth devices...');

      // Start scan, listen, stop after 10 s
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
      );

      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          _scanResults
            ..clear()
            ..addAll(results);
        });
      });

      // Wait until scanning flag becomes false (auto after timeout)
      await FlutterBluePlus.isScanning.where((s) => !s).first;
      
      if (mounted) {
        setState(() => _isScanning = false);
        if (_scanResults.isEmpty) {
          _showToast('No Bluetooth devices found nearby', isError: true);
        } else {
          _showToast('Found ${_scanResults.length} device(s)');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        _showToast('Scan failed: $e', isError: true);
      }
    }
  }

  /* ──────────── Connect & Discover ──────────── */
  Future<void> _connectTo(BluetoothDevice device) async {
    try {
      _showToast('Connecting to ${device.platformName.isNotEmpty ? device.platformName : 'device'}...');
      
      await device.connect(timeout: const Duration(seconds: 10));
      setState(() => _connectedDevice = device);

      _showToast('Connected! Discovering services...');

      List<BluetoothService> services = await device.discoverServices();
      
      bool foundNotifyChar = false;
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.notify && _notifyChar == null) {
            _notifyChar = c;
            await c.setNotifyValue(true);
            c.onValueReceived.listen(_onData);
            foundNotifyChar = true;
          }
          // If you need to WRITE, also store c if c.properties.write
        }
      }

      if (foundNotifyChar) {
        _showToast('Successfully connected to ${device.platformName.isNotEmpty ? device.platformName : 'device'}');
      } else {
        _showToast('Connected but no notification characteristic found', isError: true);
      }
      
    } catch (e) {
      String errorMessage = 'Connection failed';
      
      // Provide more specific error messages
      if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout - device may be out of range';
      } else if (e.toString().contains('bluetooth')) {
        errorMessage = 'Bluetooth error - please check if Bluetooth is enabled';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied - please grant Bluetooth permissions';
      } else if (e.toString().contains('device')) {
        errorMessage = 'Device not found or not responding';
      } else {
        errorMessage = 'Connection failed: $e';
      }
      
      if (mounted) {
        _showToast(errorMessage, isError: true);
      }
    }
  }

  void _onData(List<int> data) {
    final incoming = String.fromCharCodes(data);
    _showToast('📥 $incoming');
    debugPrint('📥 $incoming');
    // …update UI / parse JSON…
  }

  /* ──────────── UI ──────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text('BLE Connect')),
      body: Column(
        children: [
          // Test button for toast
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _startScan,
                    child: Text(_isScanning ? 'Scanning…' : 'Scan for Devices'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _showToast('Test toast message!', isError: false);
                    _showToast('Test error message!', isError: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Toast'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (_, i) {
                final r = _scanResults[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      r.device.platformName.isNotEmpty
                          ? r.device.platformName
                          : 'Unknown',
                    ),
                    subtitle: Text(r.device.remoteId.str),
                    trailing: ElevatedButton(
                      onPressed: () => _connectTo(r.device),
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
