import 'package:hive/hive.dart';
part 'habit_model.g.dart';

@HiveType(typeId: 0)
class HabitModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String icon;
  @HiveField(3)
  int targetPerDay;
  @HiveField(4)
  DateTime createdAt;
  @HiveField(5)
  bool isActive;
  @HiveField(6)
  int colorIndex;
  @HiveField(7)
  bool isSynced;
  @HiveField(8)
  DateTime? updatedAt;

  HabitModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetPerDay,
    required this.createdAt,
    required this.colorIndex,
    this.isActive = true,
    this.isSynced = false,
    this.updatedAt,
  });
}
