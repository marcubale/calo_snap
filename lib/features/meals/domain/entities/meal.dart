import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

@collection
class MealIsar {
  Id id = Isar.autoIncrement;

  late String name;
  late double calories;
  late DateTime dateTime;
  String? imagePath;

  MealIsar();

  MealIsar.fromMeal(Meal meal)
    : name = meal.name,
      calories = meal.calories,
      dateTime = meal.dateTime,
      imagePath = meal.imagePath;

  Meal toMeal() => Meal(
    name: name,
    calories: calories,
    dateTime: dateTime,
    imagePath: imagePath,
  );
}

@freezed
class Meal with _$Meal {
  const factory Meal({
    required String name,
    required double calories,
    required DateTime dateTime,
    String? imagePath,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}
