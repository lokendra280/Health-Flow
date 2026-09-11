import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


enum HabitProofType { none, photo, waterGlasses }

@immutable
class HabitProof {
  final String? photoPath;
  final int? glassesFilled;
  final DateTime capturedAt;

  const HabitProof(
      {this.photoPath, this.glassesFilled, required this.capturedAt});
}

final habitProofProvider = StateProvider<Map<String, HabitProof>>((ref) => {});


HabitProofType inferProofType(String habitName) {
  final n = habitName.toLowerCase();

  const photoKeywords = [
    'exercise',
    'workout',
    'walk',
    'run',
    'gym',
    'strength',
    'cardio',
    'stretch',
    'yoga',
    'jog',
  ];
  const waterKeywords = ['water', 'hydrat', 'drink'];

  if (waterKeywords.any(n.contains)) return HabitProofType.waterGlasses;
  if (photoKeywords.any(n.contains)) return HabitProofType.photo;
  return HabitProofType.none;
}
