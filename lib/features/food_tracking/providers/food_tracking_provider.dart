import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/utils/date_utils.dart';
import 'package:habitflow/data/services/barcode_food_service.dart';
import '../../../data/models/tracking_models.dart';
import '../../../data/repositories/journey_repository_provider.dart';
import '../../ai_plan/providers/ai_plan_provider.dart';

/// Icon per meal type — shared across the food-tracking feature.
const mealIcons = {
  'breakfast': Icons.wb_sunny_outlined,
  'lunch': Icons.lunch_dining,
  'dinner': Icons.dinner_dining,
  'snack': Icons.cookie_outlined,
};

final foodLogProvider =
    NotifierProvider.family<FoodLogController, List<FoodEntry>, DateTime>(
        FoodLogController.new);

class FoodLogController extends FamilyNotifier<List<FoodEntry>, DateTime> {
  @override
  List<FoodEntry> build(DateTime day) =>
      ref.read(journeyRepositoryProvider).foodEntriesFor(day.normalized);

  Future<void> addEntry(FoodEntry e) async {
    await addEntries([e]);
  }

  Future<void> addEntries(List<FoodEntry> entries) async {
    if (entries.isEmpty) return;
    final repo = ref.read(journeyRepositoryProvider);
    final normalizedDay = arg.normalized;

    for (final e in entries) {
      await repo.saveFoodEntry(normalizedDay, e);
      await repo.recordRecentFood(e.name);
    }

    await repo.recordActivity('meal_tracking');
    state = [...state, ...entries];
  }
}

final recentFoodsProvider = Provider<List<String>>(
    (ref) => ref.watch(journeyRepositoryProvider).recentFoodNames());
final favoriteFoodsProvider = Provider<List<String>>(
    (ref) => ref.watch(journeyRepositoryProvider).favoriteFoodNames());

final favoriteFoodControllerProvider =
    NotifierProvider<FavoriteFoodController, List<String>>(
        FavoriteFoodController.new);

class FavoriteFoodController extends Notifier<List<String>> {
  @override
  List<String> build() =>
      ref.read(journeyRepositoryProvider).favoriteFoodNames();

  Future<void> toggle(String name) async {
    final repo = ref.read(journeyRepositoryProvider);
    await repo.toggleFavoriteFood(name);
    state = repo.favoriteFoodNames();
  }
}

/// AI food scanner — camera/gallery photo → Gemini vision → candidate
/// entries. Result must be user-confirmed before it's saved.
final aiFoodScanProvider = FutureProvider.autoDispose
    .family<List<FoodEntry>, File>((ref, image) async {
  final gemini = ref.watch(geminiServiceProvider);
  return gemini.detectFood(await image.readAsBytes());
});

final barcodeFoodServiceProvider = Provider<BarcodeFoodService>((ref) {
  return BarcodeFoodService();
});

/// Barcode lookup — direct database hit, no AI involved.
final barcodeFoodLookupProvider =
    FutureProvider.autoDispose.family<FoodEntry, String>((ref, barcode) async {
  final service = ref.watch(barcodeFoodServiceProvider);
  return service.lookup(barcode);
});
