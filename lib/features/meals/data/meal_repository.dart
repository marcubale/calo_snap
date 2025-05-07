import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/isar_provider.dart';
import '../domain/entities/meal.dart';

class MealRepository {
  final Isar _isar;

  MealRepository(this._isar);

  /// This is also updating 
  Future<void> saveMeal(Meal meal) async {
    final mealIsar = MealIsar.fromMeal(meal);
    await _isar.writeTxn(() async {
      await _isar.mealIsars.put(mealIsar);
    });
  }

  Future<void> saveMealWithCalories({
    required String name,
    required double calories,
    required DateTime dateTime,
    String? imagePath,
  }) async {
    final meal = Meal(
      name: name,
      calories: calories,
      dateTime: dateTime,
      imagePath: imagePath,
    );
    await saveMeal(meal);
  }

  Future<List<Meal>> getAllMeals() async {
    final meals = await _isar.mealIsars.where().sortByDateTimeDesc().findAll();
    return meals.map((m) => m.toMeal()).toList();
  }

  Future<void> clearAllMeals() async {
    await _isar.writeTxn(() async {
      await _isar.mealIsars.clear();
    });
  }
}

final mealRepositoryProvider = FutureProvider<MealRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return MealRepository(isar);
});
