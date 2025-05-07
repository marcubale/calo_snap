import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/meal_repository.dart';
import '../../domain/entities/meal.dart';

class SaveMealViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveMeal(Meal meal) async {
    final repo = await ref.watch(mealRepositoryProvider.future);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.saveMeal(meal);
    });
  }
}

final saveMealViewModelProvider =
    AsyncNotifierProvider<SaveMealViewModel, void>(SaveMealViewModel.new);
