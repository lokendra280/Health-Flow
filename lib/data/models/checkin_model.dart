import 'package:hive/hive.dart';
part 'checkin_model.g.dart';

@HiveType(typeId: 1)
class CheckinModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String habitId;
  @HiveField(2)
  DateTime timestamp;
  @HiveField(3)
  bool isSynced;

  CheckinModel(
      {required this.id,
      required this.habitId,
      required this.timestamp,
      this.isSynced = false});
}
