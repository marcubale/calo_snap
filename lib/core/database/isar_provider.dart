import 'package:calo_snap/features/meals/domain/entities/meal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [MealIsarSchema],
    directory: dir.path,
    name: 'calo_snap_db',
  );
  return isar;
});
