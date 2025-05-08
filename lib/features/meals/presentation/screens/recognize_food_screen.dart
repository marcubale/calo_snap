import 'dart:convert';
import 'dart:typed_data';

import 'package:calo_snap/core/services/fake_image_service.dart';
import 'package:calo_snap/features/meals/presentation/viewmodels/recognize_food_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/meal.dart';
import '../viewmodels/save_meal_viewmodel.dart';

class RecognizeFoodScreen extends ConsumerStatefulWidget {
  const RecognizeFoodScreen({super.key});

  @override
  ConsumerState<RecognizeFoodScreen> createState() =>
      _RecognizeFoodScreenState();
}

class _RecognizeFoodScreenState extends ConsumerState<RecognizeFoodScreen> {
  Uint8List? _imageBytes;
  Meal? meal;
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);

      final localContext = context;

      meal = await ref
          .read(recognizeFoodViewModelProvider.notifier)
          .recognizeAndPrepare(bytes);

      if (localContext.mounted && meal != null) {
        _showConfirmMealSheet(localContext, ref, meal!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(recognizeFoodViewModelProvider);
    final localContext = context;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CaloSnap'),
        actions: [
          IconButton(
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Real button
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, size: 36),
              label: const Text('Take a Picture'),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(24.0)),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 32.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Fake button
            ElevatedButton.icon(
              onPressed: () async {
                final bytes =
                    await ref
                        .read(fakeImageServiceProvider)
                        .loadDevImageBytes();
                setState(() => _imageBytes = bytes);

                meal = await ref
                    .read(recognizeFoodViewModelProvider.notifier)
                    .recognizeAndPrepare(bytes!);
                if (localContext.mounted && meal != null) {
                  _showConfirmMealSheet(localContext, ref, meal!);
                }
              },
              icon: const Icon(Icons.camera_alt, size: 36, color: Colors.red),
              label: const Text('Use Fake Image'),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(24.0)),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 32.0),
                ),
              ),
            ),

            if (_imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            result.when(
              data:
                  (text) => Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          text ?? 'No food recognized.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) => Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
            ),

            const Spacer(),

            if (result.hasValue && result.valueOrNull != null)
              ElevatedButton.icon(
                onPressed: () async {
                  final resultText = result.valueOrNull;
                  if (resultText != null && resultText.isNotEmpty) {
                    if (meal != null) {
                      // Save the meal to the database
                      await ref
                          .read(saveMealViewModelProvider.notifier)
                          .saveMeal(meal!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Meal saved!')),
                        );
                      }
                    } else {
                      // Handle the case where meal is null
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No meal to save')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Meal'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _showConfirmMealSheet(BuildContext context, WidgetRef ref, Meal meal) {
  final nameController = TextEditingController(text: meal.name);
  final calController = TextEditingController(
    text: meal.calories.toStringAsFixed(0),
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (meal.imagePath_base64 != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(meal.imagePath_base64!),
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Food name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: calController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calories'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();
                final calories =
                    double.tryParse(calController.text.trim()) ?? 0;

                final updatedMeal = meal.copyWith(
                  name: name,
                  calories: calories,
                );
                await ref
                    .read(saveMealViewModelProvider.notifier)
                    .saveMeal(updatedMeal);

                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Meal'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
