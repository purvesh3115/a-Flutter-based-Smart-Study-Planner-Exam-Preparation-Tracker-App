import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/study_provider.dart';
import '../theme/app_theme.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../widgets/topic_status_badge.dart';

class TopicDetailScreen extends StatefulWidget {
  final Subject subject;
  const TopicDetailScreen({super.key, required this.subject});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  void _showAddTopicDialog() {
    _nameController.clear();
    _timeController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Topic',
            style: TextStyle(
                color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: const InputDecoration(
                labelText: 'Topic Name *',
                hintText: 'e.g. Integration',
                prefixIcon: Icon(Icons.topic_rounded,
                    color: AppTheme.onSurfaceMuted),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: const InputDecoration(
                labelText: 'Estimated Study Time (minutes) *',
                hintText: 'e.g. 60',
                prefixIcon: Icon(Icons.timer_rounded,
                    color: AppTheme.onSurfaceMuted),
                suffixText: 'min',
              ),
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
              final name = _nameController.text.trim();
              final timeStr = _timeController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Topic name is required')),
                );
                return;
              }
              final mins = int.tryParse(timeStr);
              if (mins == null || mins <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Enter valid study time in minutes')),
                );
                return;
              }
              context
                  .read<StudyProvider>()
                  .addTopic(widget.subject.id, name, mins);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(Topic topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status',
            style: TextStyle(
                color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusOption(ctx, topic, 0, 'Not Started',
                Icons.radio_button_unchecked_rounded,
                AppTheme.onSurfaceMuted),
            _statusOption(ctx, topic, 1, 'In Progress',
                Icons.timelapse_rounded, AppTheme.warning),
            _statusOption(ctx, topic, 2, 'Completed',
                Icons.check_circle_rounded, AppTheme.success),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(BuildContext ctx, Topic topic, int status,
      String label, IconData icon, Color color) {
    final isSelected = topic.status == status;
    return ListTile(
      onTap: () {
        context.read<StudyProvider>().updateTopicStatus(topic.id, status);
        Navigator.pop(ctx);
      },
      leading: Icon(icon, color: color),
      title: Text(label,
          style: TextStyle(
              color: isSelected ? color : AppTheme.onSurface,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal)),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: color, size: 18)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? color.withOpacity(0.1) : null,
    );
  }

  void _deleteTopic(Topic topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Topic?',
            style: TextStyle(color: AppTheme.onSurface)),
        content: Text('Delete "${topic.name}"?',
            style: const TextStyle(color: AppTheme.onSurfaceMuted)),
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
              context.read<StudyProvider>().deleteTopic(topic.id);
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
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudyProvider>();
    final color = _hexToColor(widget.subject.colorHex);
    final topics = sp.getTopicsForSubject(widget.subject.id);
    final pct = sp.getCompletionPercent(widget.subject.id);
    final completed = topics.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddTopicDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Subject header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(pct * 100).toInt()}% Complete',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 20),
                          ),
                          Text('$completed / ${topics.length} topics done',
                              style: const TextStyle(
                                  color: AppTheme.onSurfaceMuted,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: pct,
                            backgroundColor:
                                color.withOpacity(0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                            strokeWidth: 5,
                          ),
                          Text(
                            '${(pct * 100).toInt()}',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 7,
                  ),
                ),
              ],
            ),
          ),

          // Topics list
          Expanded(
            child: topics.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.topic_rounded,
                            size: 50,
                            color: AppTheme.onSurfaceMuted
                                .withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('No topics yet',
                            style: TextStyle(
                                color: AppTheme.onSurfaceMuted,
                                fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Tap + to add topics',
                            style: TextStyle(
                                color: AppTheme.onSurfaceMuted,
                                fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: topics.length,
                    itemBuilder: (ctx, i) {
                      final t = topics[i];
                      return _TopicTile(
                        topic: t,
                        color: color,
                        animIndex: i,
                        onStatusTap: () => _showStatusDialog(t),
                        onDelete: () => _deleteTopic(t),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTopicDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Topic'),
        backgroundColor: color,
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final Topic topic;
  final Color color;
  final int animIndex;
  final VoidCallback onStatusTap;
  final VoidCallback onDelete;

  const _TopicTile({
    required this.topic,
    required this.color,
    required this.animIndex,
    required this.onStatusTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(topic.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_rounded, color: AppTheme.accent),
        ),
        confirmDismiss: (_) async {
          onDelete();
          return false;
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: topic.isCompleted
                  ? AppTheme.success.withOpacity(0.3)
                  : color.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Status indicator
              GestureDetector(
                onTap: onStatusTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: topic.isCompleted
                        ? AppTheme.success.withOpacity(0.15)
                        : topic.isInProgress
                            ? AppTheme.warning.withOpacity(0.15)
                            : color.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    topic.isCompleted
                        ? Icons.check_circle_rounded
                        : topic.isInProgress
                            ? Icons.timelapse_rounded
                            : Icons.radio_button_unchecked_rounded,
                    color: topic.isCompleted
                        ? AppTheme.success
                        : topic.isInProgress
                            ? AppTheme.warning
                            : AppTheme.onSurfaceMuted,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.name,
                      style: TextStyle(
                        color: topic.isCompleted
                            ? AppTheme.onSurfaceMuted
                            : AppTheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: topic.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_rounded,
                            size: 12,
                            color: AppTheme.onSurfaceMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${topic.estimatedMinutes} min',
                          style: const TextStyle(
                              color: AppTheme.onSurfaceMuted,
                              fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                        TopicStatusBadge(status: topic.status),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onStatusTap,
                icon: const Icon(Icons.edit_rounded,
                    size: 18, color: AppTheme.onSurfaceMuted),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (animIndex * 60).ms).slideY(begin: 0.1),
      ),
    );
  }
}
