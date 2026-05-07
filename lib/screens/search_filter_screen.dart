import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/study_provider.dart';
import '../theme/app_theme.dart';
import '../models/topic.dart';
import '../widgets/topic_status_badge.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sp = context.read<StudyProvider>();
    _searchController.text = sp.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudyProvider>();
    final filteredTopics = sp.filteredTopics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filter'),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              sp.clearFilters();
            },
            child: const Text('Reset', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(sp),
          Expanded(
            child: filteredTopics.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTopics.length,
                    itemBuilder: (context, index) {
                      final topic = filteredTopics[index];
                      final subject = sp.getSubjectById(topic.subjectId);
                      final color = subject != null
                          ? Color(int.parse('FF${subject.colorHex.replaceAll('#', '')}', radix: 16))
                          : AppTheme.primary;

                      return _SearchTopicTile(
                        topic: topic,
                        subjectName: subject?.name ?? 'Unknown',
                        color: color,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(StudyProvider sp) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surface,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: sp.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search topics...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        sp.setSearchQuery('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Subject',
                  isActive: sp.filterSubjectId.isNotEmpty,
                  onTap: () => _showSubjectPicker(sp),
                  activeLabel: sp.getSubjectById(sp.filterSubjectId)?.name,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Status',
                  isActive: sp.filterStatus >= 0,
                  onTap: () => _showStatusPicker(sp),
                  activeLabel: sp.filterStatus == 0
                      ? 'Not Started'
                      : sp.filterStatus == 1
                          ? 'In Progress'
                          : sp.filterStatus == 2
                              ? 'Completed'
                              : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubjectPicker(StudyProvider sp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text('Filter by Subject', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('All Subjects'),
            selected: sp.filterSubjectId.isEmpty,
            onTap: () {
              sp.setFilterSubject('');
              Navigator.pop(context);
            },
          ),
          ...sp.subjects.map((s) => ListTile(
            title: Text(s.name),
            selected: sp.filterSubjectId == s.id,
            onTap: () {
              sp.setFilterSubject(s.id);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  void _showStatusPicker(StudyProvider sp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Text('Filter by Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('All Statuses'),
            onTap: () { sp.setFilterStatus(-1); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.radio_button_unchecked_rounded, color: AppTheme.onSurfaceMuted),
            title: const Text('Not Started'),
            onTap: () { sp.setFilterStatus(0); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.timelapse_rounded, color: AppTheme.warning),
            title: const Text('In Progress'),
            onTap: () { sp.setFilterStatus(1); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_rounded, color: AppTheme.success),
            title: const Text('Completed'),
            onTap: () { sp.setFilterStatus(2); Navigator.pop(context); },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppTheme.onSurfaceMuted.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('No topics found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Text('Try adjusting your search or filters', style: TextStyle(color: AppTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? activeLabel;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isActive ? (activeLabel ?? label) : label),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isActive ? AppTheme.primary : AppTheme.onSurfaceMuted),
        ],
      ),
      backgroundColor: isActive ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceVariant,
      side: BorderSide(color: isActive ? AppTheme.primary : Colors.transparent),
      labelStyle: TextStyle(
        color: isActive ? AppTheme.primary : AppTheme.onSurface,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}

class _SearchTopicTile extends StatelessWidget {
  final Topic topic;
  final String subjectName;
  final Color color;

  const _SearchTopicTile({
    required this.topic,
    required this.subjectName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      subjectName,
                      style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.timer_rounded, size: 12, color: AppTheme.onSurfaceMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${topic.estimatedMinutes}m',
                      style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TopicStatusBadge(status: topic.status),
        ],
      ),
    );
  }
}
