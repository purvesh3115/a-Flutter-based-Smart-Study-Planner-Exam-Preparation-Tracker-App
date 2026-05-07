import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/study_session.dart';

const _uuid = Uuid();

class StudyProvider extends ChangeNotifier {
  late Box<Subject> _subjectBox;
  late Box<Topic> _topicBox;
  late Box<StudySession> _sessionBox;

  List<Subject> _subjects = [];
  List<Topic> _topics = [];
  List<StudySession> _sessions = [];

  String _searchQuery = '';
  String _filterSubjectId = '';
  int _filterStatus = -1; // -1 = all
  DateTime? _filterDate;

  bool _isInitialized = false;

  List<Subject> get subjects => _subjects;
  List<Topic> get topics => _topics;
  List<StudySession> get sessions => _sessions;
  bool get isInitialized => _isInitialized;
  String get searchQuery => _searchQuery;
  String get filterSubjectId => _filterSubjectId;
  int get filterStatus => _filterStatus;
  DateTime? get filterDate => _filterDate;

  Future<void> init() async {
    _subjectBox = Hive.box<Subject>('subjects');
    _topicBox = Hive.box<Topic>('topics');
    _sessionBox = Hive.box<StudySession>('sessions');
    _loadAll();
    _isInitialized = true;
    notifyListeners();
  }

  void _loadAll() {
    _subjects = _subjectBox.values.toList();
    _topics = _topicBox.values.toList();
    _sessions = _sessionBox.values.toList();
  }

  // ─── SUBJECTS ───────────────────────────────────────────────────────────────

  Future<void> addSubject(String name, {String colorHex = '#6C63FF'}) async {
    final sub = Subject(
      id: _uuid.v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
      colorHex: colorHex,
    );
    await _subjectBox.put(sub.id, sub);
    _subjects = _subjectBox.values.toList();
    notifyListeners();
  }

  Future<void> updateSubject(String id, String name, String colorHex) async {
    final sub = _subjectBox.get(id);
    if (sub == null) return;
    sub.name = name.trim();
    sub.colorHex = colorHex;
    await sub.save();
    _subjects = _subjectBox.values.toList();
    notifyListeners();
  }

  Future<void> deleteSubject(String id) async {
    // Delete all topics under this subject
    final topicsToDelete =
        _topicBox.values.where((t) => t.subjectId == id).toList();
    for (final t in topicsToDelete) {
      await _topicBox.delete(t.id);
    }
    // Delete sessions for this subject
    final sessionsToDelete =
        _sessionBox.values.where((s) => s.subjectId == id).toList();
    for (final s in sessionsToDelete) {
      await _sessionBox.delete(s.id);
    }
    await _subjectBox.delete(id);
    _loadAll();
    notifyListeners();
  }

  Subject? getSubjectById(String id) => _subjectBox.get(id);

  // ─── TOPICS ─────────────────────────────────────────────────────────────────

  Future<void> addTopic(
      String subjectId, String name, int estimatedMinutes) async {
    final topic = Topic(
      id: _uuid.v4(),
      subjectId: subjectId,
      name: name.trim(),
      estimatedMinutes: estimatedMinutes,
      status: 0,
      createdAt: DateTime.now(),
    );
    await _topicBox.put(topic.id, topic);
    _topics = _topicBox.values.toList();
    notifyListeners();
  }

  Future<void> updateTopicStatus(String id, int status) async {
    final topic = _topicBox.get(id);
    if (topic == null) return;
    topic.status = status;
    topic.completedAt = status == 2 ? DateTime.now() : null;
    await topic.save();
    _topics = _topicBox.values.toList();
    notifyListeners();
  }

  Future<void> updateTopic(
      String id, String name, int estimatedMinutes) async {
    final topic = _topicBox.get(id);
    if (topic == null) return;
    topic.name = name.trim();
    topic.estimatedMinutes = estimatedMinutes;
    await topic.save();
    _topics = _topicBox.values.toList();
    notifyListeners();
  }

  Future<void> deleteTopic(String id) async {
    await _topicBox.delete(id);
    _topics = _topicBox.values.toList();
    notifyListeners();
  }

  List<Topic> getTopicsForSubject(String subjectId) =>
      _topics.where((t) => t.subjectId == subjectId).toList();

  double getCompletionPercent(String subjectId) {
    final all = getTopicsForSubject(subjectId);
    if (all.isEmpty) return 0;
    final completed = all.where((t) => t.isCompleted).length;
    return completed / all.length;
  }

  // ─── SESSIONS ───────────────────────────────────────────────────────────────

  Future<String?> addSession({
    required String subjectId,
    required String topicId,
    required String subjectName,
    required String topicName,
    required DateTime scheduledDateTime,
    required int durationMinutes,
    String? notes,
  }) async {
    // Validation: duration must be positive
    if (durationMinutes <= 0) return 'Duration must be greater than 0';

    final session = StudySession(
      id: _uuid.v4(),
      subjectId: subjectId,
      topicId: topicId,
      subjectName: subjectName,
      topicName: topicName,
      scheduledDateTime: scheduledDateTime,
      durationMinutes: durationMinutes,
      createdAt: DateTime.now(),
      notes: notes,
    );
    await _sessionBox.put(session.id, session);
    _sessions = _sessionBox.values.toList();
    notifyListeners();
    return null; // no error
  }

  Future<void> toggleSessionCompleted(String id) async {
    final s = _sessionBox.get(id);
    if (s == null) return;
    s.isCompleted = !s.isCompleted;
    await s.save();
    _sessions = _sessionBox.values.toList();
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _sessionBox.delete(id);
    _sessions = _sessionBox.values.toList();
    notifyListeners();
  }

  List<StudySession> getSessionsForDate(DateTime date) {
    return _sessions.where((s) {
      final d = s.scheduledDateTime;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList()
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
  }

  int getTodayStudyMinutes() {
    final today = DateTime.now();
    return getSessionsForDate(today)
        .where((s) => s.isCompleted)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  // ─── DASHBOARD ──────────────────────────────────────────────────────────────

  int get totalSubjects => _subjects.length;

  int get totalTopics => _topics.length;

  int get completedTopics => _topics.where((t) => t.isCompleted).length;

  int get pendingTopics => _topics.where((t) => !t.isCompleted).length;

  int get inProgressTopics => _topics.where((t) => t.isInProgress).length;

  // Returns subjects sorted by completion (lowest first)
  List<Map<String, dynamic>> get subjectsByPriority {
    return _subjects.map((s) {
      return {
        'subject': s,
        'completion': getCompletionPercent(s.id),
        'topicCount': getTopicsForSubject(s.id).length,
      };
    }).toList()
      ..sort((a, b) =>
          (a['completion'] as double).compareTo(b['completion'] as double));
  }

  // Next topic suggestions (not started or in progress, by subject priority)
  List<Map<String, dynamic>> get suggestedTopics {
    final suggestions = <Map<String, dynamic>>[];
    for (final entry in subjectsByPriority) {
      final subject = entry['subject'] as Subject;
      final topics = getTopicsForSubject(subject.id)
          .where((t) => !t.isCompleted)
          .toList()
        ..sort((a, b) => a.status.compareTo(b.status)); // in progress first
      if (topics.isNotEmpty) {
        suggestions.add({
          'subject': subject,
          'topic': topics.first,
        });
      }
      if (suggestions.length >= 3) break;
    }
    return suggestions;
  }

  // ─── SEARCH & FILTER ────────────────────────────────────────────────────────

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilterSubject(String subjectId) {
    _filterSubjectId = subjectId;
    notifyListeners();
  }

  void setFilterStatus(int status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterDate(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterSubjectId = '';
    _filterStatus = -1;
    _filterDate = null;
    notifyListeners();
  }

  List<Topic> get filteredTopics {
    List<Topic> result = List.from(_topics);

    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
              (t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_filterSubjectId.isNotEmpty) {
      result = result.where((t) => t.subjectId == _filterSubjectId).toList();
    }

    if (_filterStatus >= 0) {
      result = result.where((t) => t.status == _filterStatus).toList();
    }

    return result;
  }

  List<StudySession> get filteredSessions {
    List<StudySession> result = List.from(_sessions);

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((s) =>
              s.topicName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              s.subjectName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_filterSubjectId.isNotEmpty) {
      result =
          result.where((s) => s.subjectId == _filterSubjectId).toList();
    }

    if (_filterDate != null) {
      result = result.where((s) {
        final d = s.scheduledDateTime;
        return d.year == _filterDate!.year &&
            d.month == _filterDate!.month &&
            d.day == _filterDate!.day;
      }).toList();
    }

    result.sort(
        (a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return result;
  }
}
