import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';
import '../models/health_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _smartAlarmEnabled = true;
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _devices = [];
  BluetoothConnection? _connection;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final results = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    
    // Check if any permission was denied
    for (final result in results.entries) {
      if (result.value.isDenied) {
        debugPrint('${result.key.toString().split('.').last} permission is required');
      }
    }
  }

  Future<void> _startScan() async {
    // Check permissions first
    await _checkPermissions();
    
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      // Get bonded devices (already paired)
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devices.addAll(bondedDevices);
      });

      // Start discovery for new devices
      FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        setState(() {
          // Add device if not already in list
          if (!_devices.any((device) => device.address == result.device.address)) {
            _devices.add(result.device);
          }
        });
      });

      // Stop discovery after 4 seconds
      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluetoothSerial.instance.cancelDiscovery();
    } catch (e) {
      debugPrint('Error scanning: $e');
    }

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      
      if (_connection!.isConnected) {
        setState(() {
          _connectedDevice = device;
        });
        
        // Listen for incoming data
        _connection!.input!.listen((Uint8List data) {
          final incoming = String.fromCharCodes(data);
          debugPrint('📥 Settings received: $incoming');
          
          // Process received data
          _processReceivedData(incoming);
        }).onDone(() {
          debugPrint('Settings: Connection closed');
          setState(() {
            _connection = null;
            _connectedDevice = null;
          });
        });
      }
    } catch (e) {
      debugPrint('Error connecting: $e');
    }
  }

  Future<void> _disconnectDevice() async {
    if (_connection?.isConnected == true) {
      try {
        await _connection!.close();
        setState(() {
          _connection = null;
          _connectedDevice = null;
        });
      } catch (e) {
        debugPrint('Error disconnecting: $e');
      }
    }
  }

  /* ──────────── Process Received Data ──────────── */
  void _processReceivedData(String data) {
    try {
      // Get the HealthData provider and update it
      final healthData = Provider.of<HealthData>(context, listen: false);
      healthData.parseBluetoothData(data);
      
      debugPrint('📥 Settings: Health data updated from Bluetooth');
    } catch (e) {
      debugPrint('📥 Settings: Error processing received data: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            AppLocalizations.of(context)!.bluetooth,
            [
              if (_connectedDevice != null)
                ListTile(
                  leading: Icon(
                    Icons.bluetooth_connected,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(_connectedDevice!.name ?? 'Unknown Device'),
                  subtitle: Text(
                    AppLocalizations.of(context)!.connected,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: _disconnectDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(AppLocalizations.of(context)!.disconnect),
                  ),
                )
              else
                Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.bluetooth,
                        color: Colors.grey,
                      ),
                      title: Text(AppLocalizations.of(context)!.bluetoothDevice),
                      subtitle: Text(
                        AppLocalizations.of(context)!.notConnected,
                        style: TextStyle(color: Colors.grey),
                      ),
                      trailing: ElevatedButton(
                        onPressed: _isScanning ? null : _startScan,
                        child: Text(_isScanning
                            ? AppLocalizations.of(context)!.scanning
                            : AppLocalizations.of(context)!.scan),
                      ),
                    ),
                    if (_devices.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return ListTile(
                            leading: const Icon(Icons.bluetooth_searching),
                            title: Text(
                              device.name ?? 'Unknown Device',
                            ),
                            subtitle: Text(device.address),
                            trailing: ElevatedButton(
                              onPressed: () => _connectToDevice(device),
                              child: Text(AppLocalizations.of(context)!.connect),
                            ),
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            AppLocalizations.of(context)!.language,
            [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      value: currentLocale,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(AppLocalizations.of(context)!.english),
                        ),
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text(AppLocalizations.of(context)!.arabic),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          localeProvider.setLocale(Locale(value));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.chooseLanguage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            AppLocalizations.of(context)!.settings,
            [
              _buildSwitchTile(
                context,
                AppLocalizations.of(context)!.enableNotifications,
                _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
                Icons.notifications,
              ),
              _buildSwitchTile(
                context,
                AppLocalizations.of(context)!.enableSmartAlarm,
                _smartAlarmEnabled,
                (value) => setState(() => _smartAlarmEnabled = value),
                Icons.alarm,
              ),
              _buildTimeTile(
                context,
                AppLocalizations.of(context)!.wakeUpTime,
                _wakeUpTime,
                Icons.access_time,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            AppLocalizations.of(context)!.syncDevice,
            [
              _buildActionTile(
                context,
                AppLocalizations.of(context)!.syncDevice,
                () {
                  // Handle sync
                },
                Icons.sync,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            AppLocalizations.of(context)!.customizeGoals,
            [
              _buildActionTile(
                context,
                AppLocalizations.of(context)!.customizeGoals,
                () {
                  // Handle goals customization
                },
                Icons.flag,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildTimeTile(
    BuildContext context,
    String title,
    TimeOfDay time,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      trailing: Text(
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null && picked != time) {
          setState(() {
            _wakeUpTime = picked;
          });
        }
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    VoidCallback onTap,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
