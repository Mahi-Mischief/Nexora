import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<VolunteeringEvent> _events = [];
  List<ExtracurricularActivity> _extracurriculars = [];
  double _totalHours = 0;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = prefs.getString('volunteer_activities');
    final extracurricularsJson = prefs.getString('extracurricular_activities');

    if (activitiesJson != null) {
      final List<dynamic> decoded = jsonDecode(activitiesJson);
      setState(() {
        _events = decoded
            .map((e) => VolunteeringEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        _totalHours = _events.fold(0, (sum, e) => sum + e.hours);
      });
    }

    if (extracurricularsJson != null) {
      final List<dynamic> decoded = jsonDecode(extracurricularsJson);
      setState(() {
        _extracurriculars = decoded
            .map(
              (e) =>
                  ExtracurricularActivity.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        _sortExtracurriculars();
      });
    }
  }

  void _sortExtracurriculars() {
    _extracurriculars.sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  String _formatDate(DateTime value) => value.toIso8601String().split('T')[0];

  Future<void> _saveVolunteerEvents(List<VolunteeringEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
    await prefs.setString('volunteer_activities', encoded);
  }

  Future<void> _saveExtracurriculars(
    List<ExtracurricularActivity> activities,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(activities.map((e) => e.toJson()).toList());
    await prefs.setString('extracurricular_activities', encoded);
  }

  Future<void> _addExtracurricular() async {
    final nameCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final startDateCtrl = TextEditingController();
    final endDateCtrl = TextEditingController();
    var isCurrentlyActive = true;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Extracurricular'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Activity Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startDateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      startDateCtrl.text = _formatDate(picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Currently Active'),
                  value: isCurrentlyActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isCurrentlyActive = value;
                      if (isCurrentlyActive) {
                        endDateCtrl.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endDateCtrl,
                  readOnly: true,
                  enabled: !isCurrentlyActive,
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    hintText: isCurrentlyActive
                        ? 'Not required while active'
                        : 'YYYY-MM-DD',
                    border: const OutlineInputBorder(),
                  ),
                  onTap: () async {
                    if (isCurrentlyActive) return;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      endDateCtrl.text = _formatDate(picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    descriptionCtrl.text.trim().isEmpty ||
                    startDateCtrl.text.trim().isEmpty ||
                    (!isCurrentlyActive && endDateCtrl.text.trim().isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                final startDate = DateTime.parse(startDateCtrl.text);
                final endDate = isCurrentlyActive
                    ? null
                    : DateTime.parse(endDateCtrl.text);

                if (endDate != null && endDate.isBefore(startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('End date must be on or after start date'),
                    ),
                  );
                  return;
                }

                final newActivity = ExtracurricularActivity(
                  id: DateTime.now().microsecondsSinceEpoch,
                  name: nameCtrl.text.trim(),
                  description: descriptionCtrl.text.trim(),
                  startDate: startDate,
                  isCurrentlyActive: isCurrentlyActive,
                  endDate: endDate,
                );

                final updated = [..._extracurriculars, newActivity];
                updated.sort((a, b) => b.startDate.compareTo(a.startDate));
                await _saveExtracurriculars(updated);

                setState(() {
                  _extracurriculars = updated;
                });

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Extracurricular added')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEvent() async {
    final titleCtrl = TextEditingController();
    final hoursCtrl = TextEditingController();
    final dateCtrl = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Volunteering Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  hintText: 'e.g., Community Cleanup',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  hintText: 'e.g., 3.5',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'e.g., 2026-01-12',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    dateCtrl.text = picked.toIso8601String().split('T')[0];
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty ||
                  hoursCtrl.text.isEmpty ||
                  dateCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final event = VolunteeringEvent(
                id: DateTime.now().millisecondsSinceEpoch,
                title: titleCtrl.text,
                hours: double.parse(hoursCtrl.text),
                date: DateTime.parse(dateCtrl.text),
              );

              final events = [..._events, event];
              await _saveVolunteerEvents(events);

              setState(() {
                _events = events;
                _totalHours = _events.fold(0, (sum, e) => sum + e.hours);
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event logged successfully!')),
              );
            },
            child: const Text('Log Event'),
          ),
        ],
      ),
    );
  }

  Future<void> _editEvent(VolunteeringEvent existing) async {
    final titleCtrl = TextEditingController(text: existing.title);
    final hoursCtrl = TextEditingController(text: existing.hours.toString());
    final dateCtrl = TextEditingController(text: _formatDate(existing.date));

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Volunteering Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: existing.date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    dateCtrl.text = _formatDate(picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty ||
                  hoursCtrl.text.trim().isEmpty ||
                  dateCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final parsedHours = double.tryParse(hoursCtrl.text.trim());
              if (parsedHours == null || parsedHours <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid number of hours'),
                  ),
                );
                return;
              }

              final updatedEvents = _events
                  .map(
                    (event) => event.id == existing.id
                        ? VolunteeringEvent(
                            id: event.id,
                            title: titleCtrl.text.trim(),
                            hours: parsedHours,
                            date: DateTime.parse(dateCtrl.text),
                          )
                        : event,
                  )
                  .toList();

              await _saveVolunteerEvents(updatedEvents);

              setState(() {
                _events = updatedEvents;
                _totalHours = _events.fold(0, (sum, e) => sum + e.hours);
              });

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Event updated')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(int id) async {
    final updated = _events.where((e) => e.id != id).toList();
    await _saveVolunteerEvents(updated);

    setState(() {
      _events = updated;
      _totalHours = _events.fold(0, (sum, e) => sum + e.hours);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Event deleted')));
  }

  Future<void> _editExtracurricular(ExtracurricularActivity existing) async {
    final nameCtrl = TextEditingController(text: existing.name);
    final descriptionCtrl = TextEditingController(text: existing.description);
    final startDateCtrl = TextEditingController(
      text: _formatDate(existing.startDate),
    );
    final endDateCtrl = TextEditingController(
      text: existing.endDate == null ? '' : _formatDate(existing.endDate!),
    );
    var isCurrentlyActive = existing.isCurrentlyActive;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Extracurricular'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Activity Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startDateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: existing.startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      startDateCtrl.text = _formatDate(picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Currently Active'),
                  value: isCurrentlyActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isCurrentlyActive = value;
                      if (isCurrentlyActive) {
                        endDateCtrl.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endDateCtrl,
                  readOnly: true,
                  enabled: !isCurrentlyActive,
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    hintText: isCurrentlyActive
                        ? 'Not required while active'
                        : 'YYYY-MM-DD',
                    border: const OutlineInputBorder(),
                  ),
                  onTap: () async {
                    if (isCurrentlyActive) return;
                    final initialDate = existing.endDate ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      endDateCtrl.text = _formatDate(picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    descriptionCtrl.text.trim().isEmpty ||
                    startDateCtrl.text.trim().isEmpty ||
                    (!isCurrentlyActive && endDateCtrl.text.trim().isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                final startDate = DateTime.parse(startDateCtrl.text);
                final endDate = isCurrentlyActive
                    ? null
                    : DateTime.parse(endDateCtrl.text);

                if (endDate != null && endDate.isBefore(startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('End date must be on or after start date'),
                    ),
                  );
                  return;
                }

                final updated = _extracurriculars
                    .map(
                      (activity) => activity.id == existing.id
                          ? ExtracurricularActivity(
                              id: activity.id,
                              name: nameCtrl.text.trim(),
                              description: descriptionCtrl.text.trim(),
                              startDate: startDate,
                              isCurrentlyActive: isCurrentlyActive,
                              endDate: endDate,
                            )
                          : activity,
                    )
                    .toList();
                updated.sort((a, b) => b.startDate.compareTo(a.startDate));

                await _saveExtracurriculars(updated);

                setState(() {
                  _extracurriculars = updated;
                });

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Extracurricular updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExtracurricular(int id) async {
    final updated = _extracurriculars.where((a) => a.id != id).toList();
    await _saveExtracurriculars(updated);

    setState(() {
      _extracurriculars = updated;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Extracurricular deleted')));
  }

  Future<void> _exportLogToPdf() async {
    if (_events.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No events to export yet')));
      return;
    }

    final sortedEvents = [..._events]..sort((a, b) => b.date.compareTo(a.date));

    final doc = pw.Document();
    final dateStamp = DateTime.now().toIso8601String().split('T')[0];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Volunteering Log',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Generated on: $dateStamp'),
          pw.Text('Total Hours: ${_totalHours.toStringAsFixed(1)}'),
          pw.Text('Total Events: ${sortedEvents.length}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Event', 'Date', 'Hours'],
            data: sortedEvents
                .map(
                  (event) => [
                    event.title,
                    event.date.toIso8601String().split('T')[0],
                    event.hours.toStringAsFixed(1),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 28,
            border: pw.TableBorder.all(width: 0.5),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final fileName = 'volunteering_log_$dateStamp.pdf';

    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF export is currently available on web builds.'),
        ),
      );
      return;
    }

    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF download started')));
  }

  Future<List<String>?> _askSkillsForResume() {
    var includeSkills = false;
    final skillsCtrl = TextEditingController();

    return showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Export Resume'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Do you want to add skills to include in your resume PDF?',
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include Skills'),
                  value: includeSkills,
                  onChanged: (value) {
                    setDialogState(() {
                      includeSkills = value;
                      if (!includeSkills) {
                        skillsCtrl.clear();
                      }
                    });
                  },
                ),
                if (includeSkills)
                  TextField(
                    controller: skillsCtrl,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Skills',
                      hintText: 'Example: Leadership, Public Speaking, Excel',
                      border: OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!includeSkills) {
                  Navigator.pop(context, <String>[]);
                  return;
                }

                final skills = skillsCtrl.text
                    .split(RegExp(r'[,\n]'))
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                if (skills.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Add at least one skill or turn off Include Skills',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(context, skills);
              },
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportResumePdf() async {
    if (_extracurriculars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No extracurriculars to export yet')),
      );
      return;
    }

    final skills = await _askSkillsForResume();
    if (skills == null) return;

    final sortedActivities = [..._extracurriculars]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final dateStamp = _formatDate(DateTime.now());
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final content = <pw.Widget>[
            pw.Text(
              'Student Resume',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Generated on $dateStamp'),
            pw.SizedBox(height: 18),
            pw.Text(
              'Extracurricular Activities',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
          ];

          for (final activity in sortedActivities) {
            final dateRange = activity.endDate == null
                ? '${_formatDate(activity.startDate)} - Present'
                : '${_formatDate(activity.startDate)} - ${_formatDate(activity.endDate!)}';

            content.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    activity.name,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '$dateRange (${activity.isCurrentlyActive ? 'Active' : 'Inactive'})',
                  ),
                  pw.SizedBox(height: 2),
                  pw.Bullet(text: activity.description),
                  pw.SizedBox(height: 8),
                ],
              ),
            );
          }

          if (skills.isNotEmpty) {
            content.add(pw.SizedBox(height: 10));
            content.add(
              pw.Text(
                'Skills',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 8));
            for (final skill in skills) {
              content.add(pw.Bullet(text: skill));
            }
          }

          return content;
        },
      ),
    );

    final bytes = await doc.save();
    final fileName = 'extracurricular_resume_$dateStamp.pdf';

    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume export is currently available on web builds.'),
        ),
      );
      return;
    }

    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resume PDF download started')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteering Activities')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Volunteering Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              _totalHours.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text('Total Hours'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${_events.length}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text('Events'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export PDF'),
                      onPressed: _exportLogToPdf,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Log Event'),
                      onPressed: _addEvent,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.volunteer_activism,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No volunteering events logged yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          const Text('Start logging your volunteering hours!'),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event =
                          _events[_events.length - 1 - index]; // Reverse order
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.volunteer_activism,
                            color: Colors.blue[700],
                          ),
                          title: Text(event.title),
                          subtitle: Text(
                            '${event.date.toLocal().toString().split(' ')[0]} • ${event.hours} hours',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editEvent(event),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteEvent(event.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Extracurriculars',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.description),
                      label: const Text('Export Resume'),
                      onPressed: _exportResumePdf,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Activity'),
                      onPressed: _addExtracurricular,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _extracurriculars.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No extracurriculars added yet.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _extracurriculars.length,
                    itemBuilder: (context, index) {
                      final activity = _extracurriculars[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      activity.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activity.isCurrentlyActive
                                          ? Colors.green.shade50
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      activity.isCurrentlyActive
                                          ? 'Active'
                                          : 'Inactive',
                                      style: TextStyle(
                                        color: activity.isCurrentlyActive
                                            ? Colors.green.shade800
                                            : Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(activity.description),
                              const SizedBox(height: 10),
                              Text(
                                'Start Date: ${_formatDate(activity.startDate)}',
                              ),
                              Text(
                                activity.endDate != null
                                    ? 'End Date: ${_formatDate(activity.endDate!)}'
                                    : 'End Date: Ongoing',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _editExtracurricular(activity),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _deleteExtracurricular(activity.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class VolunteeringEvent {
  final int id;
  final String title;
  final double hours;
  final DateTime date;

  VolunteeringEvent({
    required this.id,
    required this.title,
    required this.hours,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'hours': hours,
    'date': date.toIso8601String(),
  };

  factory VolunteeringEvent.fromJson(Map<String, dynamic> json) =>
      VolunteeringEvent(
        id: json['id'],
        title: json['title'],
        hours: (json['hours'] as num).toDouble(),
        date: DateTime.parse(json['date']),
      );
}

class ExtracurricularActivity {
  final int id;
  final String name;
  final String description;
  final DateTime startDate;
  final bool isCurrentlyActive;
  final DateTime? endDate;

  ExtracurricularActivity({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.isCurrentlyActive,
    required this.endDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'startDate': startDate.toIso8601String(),
    'isCurrentlyActive': isCurrentlyActive,
    'endDate': endDate?.toIso8601String(),
  };

  factory ExtracurricularActivity.fromJson(Map<String, dynamic> json) =>
      ExtracurricularActivity(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        startDate: DateTime.parse(json['startDate']),
        isCurrentlyActive: json['isCurrentlyActive'] as bool,
        endDate: json['endDate'] == null
            ? null
            : DateTime.parse(json['endDate']),
      );
}
