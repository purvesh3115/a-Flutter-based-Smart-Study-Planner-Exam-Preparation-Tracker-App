import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/study_provider.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/subject_progress_card.dart';
import '../models/subject.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudyProvider>();
    final cp = context.watch<ConnectivityProvider>();

    final priority = sp.subjectsByPriority;
    final suggested = sp.suggestedTopics;
    final todayMin = sp.getTodayStudyMinutes();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Study Dashboard',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cp.isOnline
                              ? AppTheme.success
                              : AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cp.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: cp.isOnline
                              ? AppTheme.success
                              : AppTheme.accent,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    StatCard(
                      label: 'Total Subjects',
                      value: '${sp.totalSubjects}',
                      icon: Icons.book_rounded,
                      color: AppTheme.primary,
                      animIndex: 0,
                    ),
                    StatCard(
                      label: 'Total Topics',
                      value: '${sp.totalTopics}',
                      icon: Icons.list_alt_rounded,
                      color: AppTheme.secondary,
                      animIndex: 1,
                    ),
                    StatCard(
                      label: 'Completed',
                      value: '${sp.completedTopics}',
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.success,
                      animIndex: 2,
                    ),
                    StatCard(
                      label: 'Pending',
                      value: '${sp.pendingTopics}',
                      icon: Icons.pending_actions_rounded,
                      color: AppTheme.warning,
                      animIndex: 3,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Today's study progress
                _buildTodayProgress(todayMin),

                const SizedBox(height: 20),

                // Completion donut chart
                if (sp.totalTopics > 0) ...[
                  _buildDonutChart(sp),
                  const SizedBox(height: 20),
                ],

                // Priority subjects
                if (priority.isNotEmpty) ...[
                  _sectionHeader('📌 Priority Subjects',
                      'Lowest completion first'),
                  const SizedBox(height: 12),
                  ...priority.take(3).toList().asMap().entries.map((e) {
                    final idx = e.key;
                    final entry = e.value;
                    final subject = entry['subject'] as Subject;
                    final completion = entry['completion'] as double;
                    final topicCount = entry['topicCount'] as int;
                    final color =
                        _hexToColor(subject.colorHex);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SubjectProgressCard(
                        subjectName: subject.name,
                        completion: completion,
                        topicCount: topicCount,
                        color: color,
                        isLowest: idx == 0 && completion < 1.0,
                      ),
                    ).animate().fadeIn(delay: (idx * 100).ms).slideX(begin: -0.1);
                  }),
                  const SizedBox(height: 20),
                ],

                // Suggestions
                if (suggested.isNotEmpty) ...[
                  _sectionHeader('💡 Suggested Next Topics', 'Study these now'),
                  const SizedBox(height: 12),
                  ...suggested.asMap().entries.map((e) {
                    final idx = e.key;
                    final s = e.value['subject'] as Subject;
                    final t = e.value['topic'];
                    final color = _hexToColor(s.colorHex);
                    return _buildSuggestionTile(s, t, color, idx, context);
                  }),
                  const SizedBox(height: 20),
                ],

                if (sp.totalSubjects == 0)
                  _buildEmptyState(context),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgress(int todayMin) {
    final hours = todayMin ~/ 60;
    final mins = todayMin % 60;
    final label = hours > 0
        ? '${hours}h ${mins}m studied today'
        : '${mins}m studied today';
    final targetMin = 120; // 2 hours target
    final pct = (todayMin / targetMin).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1B2E), Color(0xFF252438)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primary.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded,
                  color: AppTheme.secondary, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Today's Progress",
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                    color: AppTheme.secondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.primary.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.secondary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Target: 2 hours/day  •  ${(pct * 100).toInt()}% achieved',
            style: const TextStyle(
              color: AppTheme.onSurfaceMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(StudyProvider sp) {
    final completed = sp.completedTopics.toDouble();
    final inProgress = sp.inProgressTopics.toDouble();
    final notStarted =
        (sp.totalTopics - sp.completedTopics - sp.inProgressTopics)
            .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Progress',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: [
                      if (completed > 0)
                        PieChartSectionData(
                          value: completed,
                          color: AppTheme.success,
                          radius: 20,
                          showTitle: false,
                        ),
                      if (inProgress > 0)
                        PieChartSectionData(
                          value: inProgress,
                          color: AppTheme.warning,
                          radius: 20,
                          showTitle: false,
                        ),
                      if (notStarted > 0)
                        PieChartSectionData(
                          value: notStarted,
                          color: AppTheme.onSurfaceMuted.withOpacity(0.4),
                          radius: 20,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _legendItem(AppTheme.success, 'Completed',
                        '${completed.toInt()}'),
                    const SizedBox(height: 8),
                    _legendItem(AppTheme.warning, 'In Progress',
                        '${inProgress.toInt()}'),
                    const SizedBox(height: 8),
                    _legendItem(
                        AppTheme.onSurfaceMuted.withOpacity(0.6),
                        'Not Started',
                        '${notStarted.toInt()}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String count) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.onSurfaceMuted, fontSize: 12)),
        ),
        Text(
          count,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppTheme.onSurfaceMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionTile(
      Subject s, dynamic t, Color color, int idx, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${idx + 1}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  s.name,
                  style: const TextStyle(
                      color: AppTheme.onSurfaceMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${t.estimatedMinutes}m',
              style:
                  TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (idx * 100).ms).slideX(begin: 0.1);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded,
                size: 44, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start Your Study Journey',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add subjects and topics\nto track your progress',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 14),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
