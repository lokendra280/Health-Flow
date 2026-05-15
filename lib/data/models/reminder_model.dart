import 'package:hive/hive.dart';
part 'reminder_model.g.dart';

@HiveType(typeId: 2)
class ReminderModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String habitId;
  @HiveField(2)
  int timeHour;
  @HiveField(3)
  int timeMinute;
  @HiveField(4)
  int frequencyIndex; // maps to ReminderFrequency enum
  @HiveField(5)
  List<int> customDays; // 1=Mon .. 7=Sun
  @HiveField(6)
  bool isEnabled;
  @HiveField(7)
  String message;
  @HiveField(8)
  bool isSynced;
  @HiveField(9)
  DateTime createdAt;
  @HiveField(10)
  DateTime? updatedAt;

  ReminderModel({
    required this.id,
    required this.habitId,
    required this.timeHour,
    required this.timeMinute,
    required this.frequencyIndex,
    required this.customDays,
    required this.message,
    required this.createdAt,
    this.isEnabled = true,
    this.isSynced = false,
    this.updatedAt,
  });
}
