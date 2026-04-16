// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter packages pub run build_runner build

part of 'models.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override final int typeId = 0;
  @override
  UserProfile read(BinaryReader r) => UserProfile(
    name: r.readString(), weightKg: r.readDouble(),
    heightCm: r.readDouble(), age: r.readInt(), isMale: r.readBool());
  @override
  void write(BinaryWriter w, UserProfile o) {
    w.writeString(o.name); w.writeDouble(o.weightKg);
    w.writeDouble(o.heightCm); w.writeInt(o.age); w.writeBool(o.isMale);
  }
}

class WorkoutLogAdapter extends TypeAdapter<WorkoutLog> {
  @override final int typeId = 1;
  @override
  WorkoutLog read(BinaryReader r) => WorkoutLog(
    id: r.readString(), name: r.readString(), type: r.readString(),
    durationMin: r.readInt(), calories: r.readInt(),
    date: DateTime.fromMillisecondsSinceEpoch(r.readInt()));
  @override
  void write(BinaryWriter w, WorkoutLog o) {
    w.writeString(o.id); w.writeString(o.name); w.writeString(o.type);
    w.writeInt(o.durationMin); w.writeInt(o.calories);
    w.writeInt(o.date.millisecondsSinceEpoch);
  }
}

class NutritionLogAdapter extends TypeAdapter<NutritionLog> {
  @override final int typeId = 2;
  @override
  NutritionLog read(BinaryReader r) => NutritionLog(
    id: r.readString(), name: r.readString(), meal: r.readString(),
    calories: r.readInt(), protein: r.readInt(), carbs: r.readInt(),
    fat: r.readInt(), date: DateTime.fromMillisecondsSinceEpoch(r.readInt()));
  @override
  void write(BinaryWriter w, NutritionLog o) {
    w.writeString(o.id); w.writeString(o.name); w.writeString(o.meal);
    w.writeInt(o.calories); w.writeInt(o.protein);
    w.writeInt(o.carbs); w.writeInt(o.fat);
    w.writeInt(o.date.millisecondsSinceEpoch);
  }
}

class SleepLogAdapter extends TypeAdapter<SleepLog> {
  @override final int typeId = 3;
  @override
  SleepLog read(BinaryReader r) => SleepLog(
    id: r.readString(),
    bedTime: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    wakeTime: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    qualityRating: r.readInt(), notes: r.readString());
  @override
  void write(BinaryWriter w, SleepLog o) {
    w.writeString(o.id);
    w.writeInt(o.bedTime.millisecondsSinceEpoch);
    w.writeInt(o.wakeTime.millisecondsSinceEpoch);
    w.writeInt(o.qualityRating); w.writeString(o.notes);
  }
}

class MoodLogAdapter extends TypeAdapter<MoodLog> {
  @override final int typeId = 4;
  @override
  MoodLog read(BinaryReader r) => MoodLog(
    id: r.readString(), mood: r.readString(), note: r.readString(),
    date: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    stressLevel: r.readInt());
  @override
  void write(BinaryWriter w, MoodLog o) {
    w.writeString(o.id); w.writeString(o.mood); w.writeString(o.note);
    w.writeInt(o.date.millisecondsSinceEpoch); w.writeInt(o.stressLevel);
  }
}

class VitalLogAdapter extends TypeAdapter<VitalLog> {
  @override final int typeId = 5;
  @override
  VitalLog read(BinaryReader r) => VitalLog(
    id: r.readString(), heartRate: r.readInt(), systolic: r.readInt(),
    diastolic: r.readInt(), spO2: r.readDouble(), temperature: r.readDouble(),
    date: DateTime.fromMillisecondsSinceEpoch(r.readInt()));
  @override
  void write(BinaryWriter w, VitalLog o) {
    w.writeString(o.id); w.writeInt(o.heartRate); w.writeInt(o.systolic);
    w.writeInt(o.diastolic); w.writeDouble(o.spO2); w.writeDouble(o.temperature);
    w.writeInt(o.date.millisecondsSinceEpoch);
  }
}

class StepLogAdapter extends TypeAdapter<StepLog> {
  @override final int typeId = 6;
  @override
  StepLog read(BinaryReader r) => StepLog(
    id: r.readString(), steps: r.readInt(), goal: r.readInt(),
    distanceKm: r.readDouble(), caloriesBurned: r.readDouble(),
    date: DateTime.fromMillisecondsSinceEpoch(r.readInt()));
  @override
  void write(BinaryWriter w, StepLog o) {
    w.writeString(o.id); w.writeInt(o.steps); w.writeInt(o.goal);
    w.writeDouble(o.distanceKm); w.writeDouble(o.caloriesBurned);
    w.writeInt(o.date.millisecondsSinceEpoch);
  }
}
