import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/study_provider.dart';
import '../theme/app_theme.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/study_session.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  void _showAddSessionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddSessionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudyProvider>();
    final sessions = sp.getSessionsForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          Expanded(
            child: sessions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return _SessionTile(
                        session: session,
                        animIndex: index,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSessionSheet,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Schedule Session'),
      ),
    );
  }

  Widget _buildDateHeader() {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: Color(0xFF2E2D45))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? 'Today' : DateFormat('EEEE').format(_selectedDate),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                DateFormat('MMMM d, yyyy').format(_selectedDate),
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (!isToday)
            TextButton(
              onPressed: () => setState(() => _selectedDate = DateTime.now()),
              child: const Text('Go to Today'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded,
              size: 64, color: AppTheme.onSurfaceMuted.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'No study sessions scheduled',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            'Keep your preparation on track!',
            style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final StudySession session;
  final int animIndex;

  const _SessionTile({required this.session, required this.animIndex});

  @override
  Widget build(BuildContext context) {
    final sp = context.read<StudyProvider>();
    final subject = sp.getSubjectById(session.subjectId);
    final color = subject != null
        ? Color(int.parse('FF${subject.colorHex.replaceAll('#', '')}', radix: 16))
        : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.isCompleted
              ? AppTheme.success.withOpacity(0.3)
              : color.withOpacity(0.2),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: session.isCompleted ? AppTheme.success : color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.topicName,
                                style: TextStyle(
                                  color: AppTheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  decoration: session.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              Text(
                                session.subjectName,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: session.isCompleted,
                          activeColor: AppTheme.success,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (_) =>
                              sp.toggleSessionCompleted(session.id),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 14, color: AppTheme.onSurfaceMuted),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('hh:mm a').format(session.scheduledDateTime),
                          style: const TextStyle(
                              color: AppTheme.onSurfaceMuted, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.timer_rounded,
                            size: 14, color: AppTheme.onSurfaceMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${session.durationMinutes} min',
                          style: const TextStyle(
                              color: AppTheme.onSurfaceMuted, fontSize: 12),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppTheme.accent),
                          onPressed: () => sp.deleteSession(session.id),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (animIndex * 50).ms).slideX(begin: 0.1);
  }
}

class _AddSessionSheet extends StatefulWidget {
  const _AddSessionSheet();

  @override
  State<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<_AddSessionSheet> {
  Subject? _selectedSubject;
  Topic? _selectedTopic;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final _durationController = TextEditingController();

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudyProvider>();
    final subjects = sp.subjects;
    final topics = _selectedSubject != null
        ? sp.getTopicsForSubject(_selectedSubject!.id)
        : <Topic>[];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Schedule Study Session',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Subject Selection
            const Text('Select Subject',
                style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Subject>(
              value: _selectedSubject,
              items: subjects.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.name));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSubject = val;
                  _selectedTopic = null;
                });
              },
              decoration: const InputDecoration(hintText: 'Choose a subject'),
            ),
            const SizedBox(height: 16),

            // Topic Selection
            const Text('Select Topic',
                style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Topic>(
              value: _selectedTopic,
              items: topics.map((t) {
                return DropdownMenuItem(value: t, child: Text(t.name));
              }).toList(),
              onChanged: (val) => setState(() => _selectedTopic = val),
              decoration: const InputDecoration(hintText: 'Choose a topic'),
              disabledHint: const Text('Select a subject first'),
            ),
            const SizedBox(height: 16),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date',
                          style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(DateFormat('MMM d, yyyy').format(_date)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time',
                          style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _time,
                          );
                          if (picked != null) setState(() => _time = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(_time.format(context)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Duration
            const Text('Duration (minutes)',
                style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 45',
                suffixText: 'min',
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedSubject == null || _selectedTopic == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select subject and topic')),
                    );
                    return;
                  }
                  final duration = int.tryParse(_durationController.text);
                  if (duration == null || duration <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid duration')),
                    );
                    return;
                  }

                  final scheduledAt = DateTime(
                    _date.year, _date.month, _date.day,
                    _time.hour, _time.minute,
                  );

                  final error = await sp.addSession(
                    subjectId: _selectedSubject!.id,
                    topicId: _selectedTopic!.id,
                    subjectName: _selectedSubject!.name,
                    topicName: _selectedTopic!.name,
                    scheduledDateTime: scheduledAt,
                    durationMinutes: duration,
                  );

                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Schedule Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
