import 'package:hive/hive.dart';

part 'topic.g.dart';

@HiveType(typeId: 1)
class Topic extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectId;

  @HiveField(2)
  String name;

  @HiveField(3)
  int estimatedMinutes; // estimated study time in minutes

  @HiveField(4)
  int status; // 0=Not Started, 1=In Progress, 2=Completed

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? completedAt;

  Topic({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.estimatedMinutes,
    this.status = 0,
    required this.createdAt,
    this.completedAt,
  });

  String get statusLabel {
    switch (status) {
      case 0:
        return 'Not Started';
      case 1:
        return 'In Progress';
      case 2:
        return 'Completed';
      default:
        return 'Not Started';
    }
  }

  bool get isCompleted => status == 2;
  bool get isInProgress => status == 1;
  bool get isNotStarted => status == 0;
}
