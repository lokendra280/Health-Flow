/// Phase 1 — personal_profile
class PersonalProfile {
  final int? age;
  final String? gender;
  final double? height;
  final String heightUnit; // 'cm' | 'in'
  final String? activityLevel; // sedentary/light/moderate/active/very_active
  final String? fitnessLevel; // beginner/intermediate/advanced
  final String? dietPreference; // omnivore/vegetarian/vegan/keto/...
  final List<String> foodAllergies;
  final List<String> foodRestrictions;

  const PersonalProfile({
    this.age,
    this.gender,
    this.height,
    this.heightUnit = 'ft',
    this.activityLevel,
    this.fitnessLevel,
    this.dietPreference,
    this.foodAllergies = const [],
    this.foodRestrictions = const [],
  });

  bool get isComplete =>
      age != null &&
      gender != null &&
      height != null &&
      activityLevel != null &&
      fitnessLevel != null;

  PersonalProfile copyWith({
    int? age,
    String? gender,
    double? height,
    String? heightUnit,
    String? activityLevel,
    String? fitnessLevel,
    String? dietPreference,
    List<String>? foodAllergies,
    List<String>? foodRestrictions,
  }) {
    return PersonalProfile(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      heightUnit: heightUnit ?? this.heightUnit,
      activityLevel: activityLevel ?? this.activityLevel,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      dietPreference: dietPreference ?? this.dietPreference,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      foodRestrictions: foodRestrictions ?? this.foodRestrictions,
    );
  }

  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender,
        'height': height,
        'heightUnit': heightUnit,
        'activityLevel': activityLevel,
        'fitnessLevel': fitnessLevel,
        'dietPreference': dietPreference,
        'foodAllergies': foodAllergies,
        'foodRestrictions': foodRestrictions,
      };

  factory PersonalProfile.fromJson(Map<String, dynamic> json) =>
      PersonalProfile(
        age: json['age'] as int?,
        gender: json['gender'] as String?,
        height: (json['height'] as num?)?.toDouble(),
        heightUnit: json['heightUnit'] as String? ?? 'cm',
        activityLevel: json['activityLevel'] as String?,
        fitnessLevel: json['fitnessLevel'] as String?,
        dietPreference: json['dietPreference'] as String?,
        foodAllergies:
            (json['foodAllergies'] as List?)?.cast<String>() ?? const [],
        foodRestrictions:
            (json['foodRestrictions'] as List?)?.cast<String>() ?? const [],
      );

  /// Column-name subset for the shared `journey_profiles` row — merged
  /// with JourneyGoal.toSupabaseRow() by the sync service, since both
  /// models write to the same table. Does NOT include user_id/
  /// updated_at — the caller (JourneySupabaseService) adds those once
  /// when combining both maps, so they aren't duplicated/overwritten
  /// inconsistently between the two toSupabaseRow() calls.
  Map<String, dynamic> toSupabaseRow() => {
        'age': age,
        'gender': gender,
        'height': height,
        'height_unit': heightUnit,
        'activity_level': activityLevel,
        'fitness_level': fitnessLevel,
        'diet_preference': dietPreference,
        'food_allergies': foodAllergies,
        'food_restrictions': foodRestrictions,
      };

  factory PersonalProfile.fromSupabaseRow(Map<String, dynamic> row) =>
      PersonalProfile(
        age: row['age'] as int?,
        gender: row['gender'] as String?,
        height: (row['height'] as num?)?.toDouble(),
        heightUnit: row['height_unit'] as String? ?? 'cm',
        activityLevel: row['activity_level'] as String?,
        fitnessLevel: row['fitness_level'] as String?,
        dietPreference: row['diet_preference'] as String?,
        foodAllergies:
            (row['food_allergies'] as List?)?.cast<String>() ?? const [],
        foodRestrictions:
            (row['food_restrictions'] as List?)?.cast<String>() ?? const [],
      );
}
