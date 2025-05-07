import 'dart:async';

import 'package:calo_snap/core/database/isar_provider.dart';
import 'package:calo_snap/features/meals/data/meal_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../domain/entities/meal.dart';

class MealHistoryViewModel extends AsyncNotifier<Map<DateTime, List<Meal>>> {
  @override
  FutureOr<Map<DateTime, List<Meal>>> build() async {
    final repo = await ref.watch(mealRepositoryProvider.future);
    final allMeals = await repo.getAllMeals();

    final Map<DateTime, List<Meal>> groupedMeals = {};
    for (final meal in allMeals) {
      final key = DateTime(
        meal.dateTime.year,
        meal.dateTime.month,
        meal.dateTime.day,
      );
      groupedMeals.putIfAbsent(key, () => []).add(meal);
    }

    return groupedMeals;
  }
}

// final mealHistoryViewModelProvider =
//     AsyncNotifierProvider<MealHistoryViewModel, Map<DateTime, List<Meal>>>(
//       MealHistoryViewModel.new,
//     );

final mealHistoryViewModelProvider = StreamProvider<Map<DateTime, List<Meal>>>((
  ref,
) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) {
      return isar.mealIsars.where().watch(fireImmediately: true).map((
        isarMeals,
      ) {
        final Map<DateTime, List<Meal>> groupedMeals = {};
        for (final isarMeal in isarMeals) {
          final meal = isarMeal.toMeal();
          final key = DateTime(
            meal.dateTime.year,
            meal.dateTime.month,
            meal.dateTime.day,
          );
          groupedMeals.putIfAbsent(key, () => []).add(meal);
        }
        return groupedMeals;
      });
    },
    error: (e, _) => Stream.error(e ?? 'Unknown Isar init error'),
    loading: () => const Stream.empty(),
  );
});
