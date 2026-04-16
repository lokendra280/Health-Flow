import 'package:hive_flutter/hive_flutter.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0) String name;
  @HiveField(1) double weightKg;
  @HiveField(2) double heightCm;
  @HiveField(3) int age;
  @HiveField(4) bool isMale;

  UserProfile({required this.name, required this.weightKg,
    required this.heightCm, required this.age, required this.isMale});
}

@HiveType(typeId: 1)
class WorkoutLog extends HiveObject {
  @HiveField(0) String id, name, type;
  @HiveField(1) int durationMin, calories;
  @HiveField(2) DateTime date;

  WorkoutLog({required this.id, required this.name, required this.type,
    required this.durationMin, required this.calories, required this.date});
}

@HiveType(typeId: 2)
class NutritionLog extends HiveObject {
  @HiveField(0) String id, name, meal;
  @HiveField(1) int calories, protein, carbs, fat;
  @HiveField(2) DateTime date;

  NutritionLog({required this.id, required this.name, required this.meal,
    required this.calories, required this.protein, required this.carbs,
    required this.fat, required this.date});
}

@HiveType(typeId: 3)
class SleepLog extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) DateTime bedTime, wakeTime;
  @HiveField(2) int qualityRating; // 1-5
  @HiveField(3) String notes;

  SleepLog({required this.id, required this.bedTime, required this.wakeTime,
    required this.qualityRating, required this.notes});

  double get hours => wakeTime.difference(bedTime).inMinutes / 60;
}

@HiveType(typeId: 4)
class MoodLog extends HiveObject {
  @HiveField(0) String id, mood, note;
  @HiveField(1) DateTime date;
  @HiveField(2) int stressLevel; // 1-10

  MoodLog({required this.id, required this.mood, required this.note,
    required this.date, required this.stressLevel});
}

@HiveType(typeId: 5)
class VitalLog extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) int heartRate, systolic, diastolic;
  @HiveField(2) double spO2, temperature;
  @HiveField(3) DateTime date;

  VitalLog({required this.id, required this.heartRate, required this.systolic,
    required this.diastolic, required this.spO2, required this.temperature,
    required this.date});
}

@HiveType(typeId: 6)
class StepLog extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) int steps, goal;
  @HiveField(2) double distanceKm, caloriesBurned;
  @HiveField(3) DateTime date;

  StepLog({required this.id, required this.steps, required this.goal,
    required this.distanceKm, required this.caloriesBurned, required this.date});
}
