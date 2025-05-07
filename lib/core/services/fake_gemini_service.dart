import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gemini_service.dart';

class FakeGeminiService implements GeminiService {
  @override
  Future<String> recognizeFood(Uint8List imageBytes) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'Strawberries';
  }
}

final fakeGeminiServiceProvider = Provider<FakeGeminiService>((ref) {
  return FakeGeminiService();
});
