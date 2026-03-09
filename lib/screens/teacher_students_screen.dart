import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/teacher_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  List<dynamic> _students = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('nexora_token');
      if (_token != null) {
        final students = await TeacherService.getStudents(_token!);
        setState(() {
          _students = students;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    }
  }

  Future<void> _viewStudentActivities(dynamic student) async {
    try {
      final activities = await TeacherService.getStudentActivities(
        _token!,
        student['id'],
      );
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StudentActivitiesDetailScreen(
            student: student,
            activities: activities,
            token: _token!,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading activities: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudents,
              child: _students.isEmpty
                  ? const Center(child: Text('No students yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final totalHours =
                            double.tryParse(
                              student['total_hours'].toString(),
                            ) ??
                            0.0;
                        final activityCount = student['activity_count'] ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundImage: AssetImage(
                                'assets/user_icon.jpg',
                              ),
                            ),
                            title: Text(
                              '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'
                                      .trim()
                                      .isEmpty
                                  ? student['username']
                                  : '${student['first_name']} ${student['last_name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Grade: ${student['grade'] ?? 'N/A'}'),
                                Text('Activities: $activityCount'),
                                Text(
                                  'Total Hours: ${totalHours.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => _viewStudentActivities(student),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class StudentActivitiesDetailScreen extends StatefulWidget {
  final dynamic student;
  final List<dynamic> activities;
  final String token;

  const StudentActivitiesDetailScreen({
    super.key,
    required this.student,
    required this.activities,
    required this.token,
  });

  @override
  State<StudentActivitiesDetailScreen> createState() =>
      _StudentActivitiesDetailScreenState();
}

class _StudentActivitiesDetailScreenState
    extends State<StudentActivitiesDetailScreen> {
  late List<dynamic> _activities;

  @override
  void initState() {
    super.initState();
    _activities = widget.activities;
  }

  Future<void> _addActivity() async {
    final titleCtrl = TextEditingController();
    final hoursCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    String activityType = 'volunteering';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Activity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: activityType,
                  decoration: const InputDecoration(labelText: 'Activity Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'volunteering',
                      child: Text('Volunteering'),
                    ),
                    DropdownMenuItem(
                      value: 'fbla_event',
                      child: Text('FBLA Event'),
                    ),
                    DropdownMenuItem(
                      value: 'community_service',
                      child: Text('Community Service'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) => setDialogState(() => activityType = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Food Bank Volunteer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date',
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty ||
                    hoursCtrl.text.isEmpty ||
                    dateCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill required fields'),
                    ),
                  );
                  return;
                }

                final activity = {
                  'activity_type': activityType,
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'hours': double.parse(hoursCtrl.text),
                  'date': dateCtrl.text,
                };

                final success = await TeacherService.addStudentActivity(
                  widget.token,
                  widget.student['id'],
                  activity,
                );

                if (!context.mounted) return;
                Navigator.pop(context, success);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // Reload activities
      final updatedActivities = await TeacherService.getStudentActivities(
        widget.token,
        widget.student['id'],
      );
      setState(() => _activities = updatedActivities);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity added successfully')),
        );
      }
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final pdfUrl = await TeacherService.getStudentPdfUrl(
        widget.student['id'],
      );
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nexora_token');

      // For web, we'll open in a new tab with the token as a query param
      final urlWithToken = Uri.parse(
        pdfUrl,
      ).replace(queryParameters: {'token': 'Bearer $token'});

      if (await canLaunchUrl(urlWithToken)) {
        await launchUrl(urlWithToken, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download PDF')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final totalHours = _activities.fold<double>(
      0.0,
      (sum, a) => sum + (double.tryParse(a['hours'].toString()) ?? 0.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.student['first_name'] ?? widget.student['username']}\'s Activities',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF Log',
            onPressed: _downloadPdf,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addActivity,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.student['first_name'] ?? ''} ${widget.student['last_name'] ?? ''}'
                              .trim()
                              .isEmpty
                          ? widget.student['username']
                          : '${widget.student['first_name']} ${widget.student['last_name']}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Username: ${widget.student['username']}')),
                        Chip(label: Text('Grade: ${widget.student['grade'] ?? 'N/A'}')),
                        Chip(label: Text('School: ${widget.student['school'] ?? 'N/A'}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${widget.student['email'] ?? 'N/A'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Total Activities',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_activities.length}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Total Hours', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          totalHours.toStringAsFixed(1),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _activities.isEmpty
                  ? const Center(child: Text('No activities logged yet'))
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final activity = _activities[index];
                        final date = DateTime.parse(activity['date']);
                        final hours =
                            double.tryParse(activity['hours'].toString()) ?? 0.0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colors.secondaryContainer,
                              child: Text(
                                '${hours.toStringAsFixed(1)}h',
                                style: TextStyle(
                                  color: colors.onSecondaryContainer,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(
                              activity['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Type: ${activity['activity_type']}'),
                                Text(
                                  'Date: ${date.toLocal().toString().split(' ')[0]}',
                                ),
                                if (activity['description'] != null &&
                                    activity['description'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      activity['description'],
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
