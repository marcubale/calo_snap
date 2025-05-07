import 'dart:typed_data';

import 'package:calo_snap/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService(String apiKey)
    : _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

  /// Recognize food from image using Gemini
  Future<String?> recognizeFood(Uint8List imageBytes) async {
    final prompt = Content.multi([
      TextPart(
        'What food is shown in this picture? Provide a short and simple answer.',
      ),
      DataPart('image/jpeg', imageBytes),
    ]);

    final response = await _model.generateContent([prompt]);

    return response.text;
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final apiKey = geminiApiKey;
  return GeminiService(apiKey);
});
