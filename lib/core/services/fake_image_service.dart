import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakeImageService {
  /// Load an image from local disk (development-only) or from assets
  Future<Uint8List?> loadDevImageBytes() async {
    // OPTION A: Load from assets (e.g., assets/dev_food.jpg)
    final byteData = await rootBundle.load(
      'assets/strawberries_image_asset.jpg',
    );
    return byteData.buffer.asUint8List();

    // OPTION B (alternative): Load from a fixed path
    // final file = File('/Users/yourname/Pictures/dev_image.jpg');
    // return await file.readAsBytes();
  }
}

final fakeImageServiceProvider = Provider<FakeImageService>((ref) {
  return FakeImageService();
});
