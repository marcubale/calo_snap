import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:calo_snap/core/services/gemini_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/fatsecret_service.dart';
import '../../domain/entities/meal.dart';

class RecognizeFoodViewModel extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<void> recognize(Uint8List imageBytes) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final gemini = ref.read(geminiServiceProvider);
      return await gemini.recognizeFood(imageBytes);
    });
  }

  Future<Meal?> recognizeAndPrepare(Uint8List imageBytes) async {
    state = const AsyncLoading();
    Meal? meal;

    state = await AsyncValue.guard(() async {
      final gemini = ref.read(geminiServiceProvider);
      final fatSecret = ref.read(fatSecretServiceProvider);

      final foodName = await gemini.recognizeFood(imageBytes);
      if (foodName == null || foodName.isEmpty) return null;

      final fatResult = await fatSecret.searchFood(foodName);
      final first = fatResult?['foods']?['food'];
      final food = (first is List ? first.first : first) ?? {};
      final calories = extractCaloriesFromDescription(
        food['food_description'] ?? '',
      );

      meal = Meal(
        name: foodName,
        calories: calories,
        dateTime: DateTime.now(),
        imagePath_base64: base64Encode(imageBytes),
      );

      state = AsyncValue.data(foodName);
      return foodName;
    });

    return meal;
  }

  extractCaloriesFromDescription(String foodDescription) {
    final regex = RegExp(r'Calories:\s*(\d+)\s*kcal');
    final match = regex.firstMatch(foodDescription);
    if (match != null) {
      final caloriesString = match.group(1);
      if (caloriesString != null) {
        return double.tryParse(caloriesString) ?? 0.0;
      }
    }
    return 0.0;
  }
}

final recognizeFoodViewModelProvider =
    AsyncNotifierProvider<RecognizeFoodViewModel, String?>(
      RecognizeFoodViewModel.new,
    );
