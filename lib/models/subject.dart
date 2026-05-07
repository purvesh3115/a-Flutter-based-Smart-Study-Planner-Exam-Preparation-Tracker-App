import 'package:hive/hive.dart';

part 'subject.g.dart';

@HiveType(typeId: 0)
class Subject extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  String colorHex;

  Subject({
    required this.id,
    required this.name,
    required this.createdAt,
    this.colorHex = '#6C63FF',
  });
}
