import 'package:hive/hive.dart';
part 'challenge_model.g.dart';

@HiveType(typeId: 3)
class ChallengeModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String description;
  @HiveField(3)
  String emoji;
  @HiveField(4)
  List<String> habitIds;
  @HiveField(5)
  int targetDays;
  @HiveField(6)
  DateTime startDate;
  @HiveField(7)
  DateTime? completedDate;
  @HiveField(8)
  int statusIndex; // 0=active,1=completed,2=failed
  @HiveField(9)
  int colorIndex;
  @HiveField(10)
  bool isSynced;
  @HiveField(11)
  DateTime? updatedAt;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.habitIds,
    required this.targetDays,
    required this.startDate,
    required this.colorIndex,
    this.completedDate,
    this.statusIndex = 0,
    this.isSynced = false,
    this.updatedAt,
  });
}
