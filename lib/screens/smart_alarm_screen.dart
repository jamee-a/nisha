import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SmartAlarmScreen extends StatefulWidget {
  const SmartAlarmScreen({Key? key}) : super(key: key);

  @override
  State<SmartAlarmScreen> createState() => _SmartAlarmScreenState();
}

class _SmartAlarmScreenState extends State<SmartAlarmScreen> {
  TimeOfDay selectedTime = TimeOfDay.now();
  bool alarmEnabled = false;

  void _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(local.smartAlarm),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.alarm, size: 100, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text(
              local.wakeUpTime,
              style: const TextStyle(fontSize: 18, fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 10),
            Text(
              _formatTime(selectedTime),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                local.enableSmartAlarm,
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
              value: alarmEnabled,
              onChanged: (val) {
                setState(() {
                  alarmEnabled = val;
                });
              },
              activeColor: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickTime,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Text(
                local.chooseAlarmTime,
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
