import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/study_provider.dart';
import '../theme/app_theme.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../widgets/topic_status_badge.dart';
import 'topic_detail_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _subjectController = TextEditingController();
  int _selectedColorIndex = 0;

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

  void _showAddSubjectDialog() {
    _subjectController.clear();
    _selectedColorIndex = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          title: const Text(
            'Add Subject',
            style: TextStyle(
                color: AppTheme.onSurface, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _subjectController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  hintText: 'e.g. Mathematics',
                  prefixIcon: Icon(Icons.book_rounded,
                      color: AppTheme.onSurfaceMuted),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Color',
                    style: TextStyle(
                        color: AppTheme.onSurfaceMuted, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppTheme.subjectColors
                    .asMap()
                    .entries
                    .map((e) => GestureDetector(
                          onTap: () =>
                              setDlgState(() => _selectedColorIndex = e.key),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: e.value,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColorIndex == e.key
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: _selectedColorIndex == e.key
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.onSurfaceMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _subjectController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Subject name is required')),
                  );
                  return;
                }
                context.read<StudyProvider>().addSubject(
                      name,
                      colorHex: _colorToHex(
                          AppTheme.subjectColors[_selectedColorIndex]),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      }),
    );
  }

  void _showDeleteConfirm(Subject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?',
            style: TextStyle(color: AppTheme.onSurface)),
        content: Text(
          'All topics under "${subject.name}" will also be deleted.',
          style: const TextStyle(color: AppTheme.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.onSurfaceMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent),
            onPressed: () {
              context.read<StudyProvider>().deleteSubject(subject.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudyProvider>();
    final subjects = sp.subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddSubjectDialog,
            tooltip: 'Add Subject',
          ),
        ],
      ),
      body: subjects.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (ctx, i) {
                final s = subjects[i];
                final color = _hexToColor(s.colorHex);
                final topics = sp.getTopicsForSubject(s.id);
                final pct = sp.getCompletionPercent(s.id);

                return Dismissible(
                  key: Key(s.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: AppTheme.accent),
                  ),
                  confirmDismiss: (_) async {
                    _showDeleteConfirm(s);
                    return false;
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SubjectCard(
                      subject: s,
                      color: color,
                      topicCount: topics.length,
                      completedCount:
                          topics.where((t) => t.isCompleted).length,
                      completion: pct,
                      animIndex: i,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TopicDetailScreen(subject: s),
                        ),
                      ),
                      onDelete: () => _showDeleteConfirm(s),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubjectDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Subject'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.book_rounded,
                size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text('No Subjects Yet',
              style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Tap "Add Subject" to get started',
              style: TextStyle(
                  color: AppTheme.onSurfaceMuted, fontSize: 14)),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final Color color;
  final int topicCount;
  final int completedCount;
  final double completion;
  final int animIndex;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.color,
    required this.topicCount,
    required this.completedCount,
    required this.completion,
    required this.animIndex,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      subject.name.isNotEmpty
                          ? subject.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount / $topicCount topics completed',
                        style: const TextStyle(
                            color: AppTheme.onSurfaceMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${(completion * 100).toInt()}%',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 18),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.onSurfaceMuted, size: 20),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completion,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (animIndex * 70).ms).slideX(begin: -0.05);
  }
}
