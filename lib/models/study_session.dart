import 'package:hive/hive.dart';

part 'study_session.g.dart';

@HiveType(typeId: 2)
class StudySession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectId;

  @HiveField(2)
  String topicId;

  @HiveField(3)
  String subjectName;

  @HiveField(4)
  String topicName;

  @HiveField(5)
  DateTime scheduledDateTime;

  @HiveField(6)
  int durationMinutes;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  String? notes;

  StudySession({
    required this.id,
    required this.subjectId,
    required this.topicId,
    required this.subjectName,
    required this.topicName,
    required this.scheduledDateTime,
    required this.durationMinutes,
    this.isCompleted = false,
    required this.createdAt,
    this.notes,
  });
}
