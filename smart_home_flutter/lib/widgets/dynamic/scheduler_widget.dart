import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SchedulerWidget extends StatefulWidget {
  final String title;
  final Map<String, dynamic> properties;
  final Function(Map<String, dynamic>) onScheduleSet;

  const SchedulerWidget({
    Key? key,
    required this.title,
    required this.properties,
    required this.onScheduleSet,
  }) : super(key: key);

  @override
  State<SchedulerWidget> createState() => _SchedulerWidgetState();
}

class _SchedulerWidgetState extends State<SchedulerWidget> {
  final List<Map<String, dynamic>> _schedules = [];
  
  @override
  void initState() {
    super.initState();
    _loadInitialSchedules();
  }
  
  void _loadInitialSchedules() {
    final List<dynamic> initialSchedules = widget.properties['schedules'] ?? [];
    for (final schedule in initialSchedules) {
      _schedules.add(Map<String, dynamic>.from(schedule));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> zones = widget.properties['zones'] ?? [];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            ...zones.map<Widget>((zone) {
              return _buildZoneItem(Map<String, dynamic>.from(zone));
            }).toList(),
            const SizedBox(height: 8.0),
            if (_schedules.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Current Schedules',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              ..._schedules.map<Widget>((schedule) {
                return _buildScheduleItem(schedule);
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildZoneItem(Map<String, dynamic> zone) {
    final String zoneName = zone['name'] ?? 'Zone';
    final int maxDuration = zone['maxDuration'] ?? 30;
    
    return ListTile(
      title: Text(zoneName),
      subtitle: Text('Max duration: $maxDuration min'),
      trailing: IconButton(
        icon: const Icon(Icons.schedule),
        onPressed: () {
          _showScheduleDialog(zone);
        },
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule) {
    final String zoneName = schedule['zoneName'] ?? 'Unknown Zone';
    final String startTime = schedule['startTime'] ?? '00:00';
    final int duration = schedule['duration'] ?? 0;
    final List<String> days = List<String>.from(schedule['days'] ?? []);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: Colors.grey[100],
      child: ListTile(
        title: Text('$zoneName - $startTime (${duration}min)'),
        subtitle: Text('Days: ${days.join(", ")}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _schedules.remove(schedule);
            });
            widget.onScheduleSet({'schedules': _schedules});
          },
        ),
      ),
    );
  }

  void _showScheduleDialog(Map<String, dynamic> zone) {
    final String zoneId = zone['id'] ?? '';
    final String zoneName = zone['name'] ?? 'Zone';
    final int maxDuration = zone['maxDuration'] ?? 30;
    
    TimeOfDay selectedTime = TimeOfDay.now();
    int selectedDuration = 10;
    List<bool> selectedDays = List.generate(7, (index) => false);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Schedule $zoneName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start Time:'),
                  ListTile(
                    title: Text(selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Duration (max $maxDuration min):'),
                  Slider(
                    value: selectedDuration.toDouble(),
                    min: 1,
                    max: maxDuration.toDouble(),
                    divisions: maxDuration,
                    label: '$selectedDuration min',
                    onChanged: (value) {
                      setState(() {
                        selectedDuration = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Days:'),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _dayChip('Mon', 0, selectedDays, (index, value) {
                        setState(() {
                          selectedDays[index] = value;
                        });
                      }),
                      _dayChip('Tue', 1, selectedDays, (index, value) {
                        setState(() {
                          selectedDays[index] = value;
                        });
                      }),
                      _dayChip('Wed', 2, selectedDays, (index, value) {
                        setState(() {
                          selectedDays[index] = value;
                        });
                      }),
                      _dayChip('Thu', 3, selectedDays, (index, value) {
                        setState(() {
                          selectedDays[index] = value;
                        });
                      }),
                      _dayChip('Fri', 4, selectedDays, (index, value) {
                        setState(() {
                          selectedDays[index] = value;
                        });
                      }),
                      _dayChip('Sat', 5, selectedDays, (index, value) {
                        setState(() {
                          selectedDays[index] = value;
                        });
                      }),
                      _dayChip('Sun', 6, selectedDays, (index, value) {
                        setState(() {
                          selectedDays[index] = value;
                        });
                      }),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Convert selected days to day names
                  final List<String> dayNames = [];
                  final List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  for (int i = 0; i < selectedDays.length; i++) {
                    if (selectedDays[i]) {
                      dayNames.add(dayLabels[i]);
                    }
                  }
                  
                  if (dayNames.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one day')),
                    );
                    return;
                  }
                  
                  // Format time as string
                  final String timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                  
                  // Create schedule object
                  final Map<String, dynamic> newSchedule = {
                    'zoneId': zoneId,
                    'zoneName': zoneName,
                    'startTime': timeString,
                    'duration': selectedDuration,
                    'days': dayNames,
                  };
                  
                  // Add to schedules list
                  setState(() {
                    _schedules.add(newSchedule);
                  });
                  
                  // Notify parent
                  widget.onScheduleSet({'schedules': _schedules});
                  
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dayChip(String label, int index, List<bool> selectedDays, Function(int, bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selectedDays[index],
      onSelected: (bool value) {
        onSelected(index, value);
      },
    );
  }
}