import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/meal_repository.dart';
import '../../domain/entities/meal.dart';
import '../viewmodels/meal_history_viewmodel.dart';

class MealHistoryScreen extends ConsumerStatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  ConsumerState<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends ConsumerState<MealHistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final mealMap = ref.watch(mealHistoryViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meal History')),
      body: SafeArea(
        child: mealMap.when(
          data: (mealsByDate) {
            final selectedDate = _stripTime(_selectedDay ?? _focusedDay);
            final meals = mealsByDate[selectedDate] ?? [];
            final totalCalories = meals.fold<double>(
              0,
              (sum, meal) => sum + meal.calories,
            );
            return Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  eventLoader: (day) {
                    return mealsByDate[_stripTime(day)] ?? [];
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Total: ${totalCalories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children:
                        (mealsByDate[_stripTime(_selectedDay ?? _focusedDay)] ??
                                [])
                            .map(
                              (meal) => GestureDetector(
                                onTap: () => _showEditMealSheet(context, meal),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading:
                                        meal.imagePath_base64 != null
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.memory(
                                                base64Decode(
                                                  meal.imagePath_base64!,
                                                ),
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                            : const Icon(
                                              Icons.restaurant_menu,
                                              color: Colors.green,
                                            ),
                                    title: Text(meal.name),
                                    subtitle: Text(
                                      '${meal.calories.toStringAsFixed(0)} kcal',
                                    ),
                                    trailing: Text(
                                      '${meal.dateTime.hour.toString().padLeft(2, '0')}:${meal.dateTime.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void _showEditMealSheet(BuildContext context, Meal meal) {
    final controller = TextEditingController(
      text: meal.calories.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (meal.imagePath_base64 != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.memory(
                      base64Decode(meal.imagePath_base64!),
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final updatedCalories = double.tryParse(controller.text);
                    if (updatedCalories != null) {
                      final updatedMeal = meal.copyWith(
                        calories: updatedCalories,
                      );
                      final repo = await ref.read(
                        mealRepositoryProvider.future,
                      );
                      await repo.saveMeal(updatedMeal);

                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
