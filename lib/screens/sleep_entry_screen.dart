import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/sleep_data.dart';

class SleepEntryScreen extends StatefulWidget {
  final Function(SleepData) onSave;

  const SleepEntryScreen({Key? key, required this.onSave}) : super(key: key);

  @override
  _SleepEntryScreenState createState() => _SleepEntryScreenState();
}

class _SleepEntryScreenState extends State<SleepEntryScreen> {
  TimeOfDay? _sleepTime;
  TimeOfDay? _wakeTime;
  Duration _deepSleep = Duration(hours: 2);

  void _saveEntry() {
    if (_sleepTime == null || _wakeTime == null) return;

    final now = DateTime.now();
    final sleepDate = DateTime(
      now.year,
      now.month,
      now.day,
      _sleepTime!.hour,
      _sleepTime!.minute,
    );
    final wakeDate = DateTime(
      now.year,
      now.month,
      now.day,
      _wakeTime!.hour,
      _wakeTime!.minute,
    );

    final sleepDuration = wakeDate.isBefore(sleepDate)
        ? wakeDate.add(Duration(days: 1)).difference(sleepDate)
        : wakeDate.difference(sleepDate);

    final newEntry = SleepData(
      date: now,
      sleepDuration: sleepDuration,
      deepSleepDuration: _deepSleep,
    );

    widget.onSave(newEntry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(local.enterSleepData),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) setState(() => _sleepTime = time);
              },
              child: Text(_sleepTime == null
                  ? local.selectSleepTime
                  : '${local.sleep}: ${_sleepTime!.format(context)}'),
            ),
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) setState(() => _wakeTime = time);
              },
              child: Text(_wakeTime == null
                  ? local.selectWakeTime
                  : '${local.wake}: ${_wakeTime!.format(context)}'),
            ),
            Slider(
              value: _deepSleep.inHours.toDouble(),
              min: 0,
              max: 6,
              divisions: 6,
              label: "${_deepSleep.inHours} ${local.deepSleepHours}",
              onChanged: (value) => setState(
                () => _deepSleep = Duration(hours: value.toInt()),
              ),
            ),
            ElevatedButton(
              onPressed: _saveEntry,
              child: Text(local.saveData),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
