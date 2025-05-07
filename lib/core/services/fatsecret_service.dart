import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FatSecretService {
  final String cliendId;
  final String clientSecret;
  final Dio _dio;

  String? _accessToken;
  DateTime? _tokenExpiration;

  FatSecretService({required this.cliendId, required this.clientSecret})
    : _dio = Dio();

  Future<void> _authenticate() async {
    if (_accessToken != null && _tokenExpiration!.isAfter(DateTime.now())) {
      return;
    }

    final credentials = base64Encode(utf8.encode('$cliendId:$clientSecret'));
    final response = await _dio.post(
      'https://oauth.fatsecret.com/connect/token',
      options: Options(
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
      data: 'grant_type=client_credentials&scope=premier',
    );

    final data = response.data;
    _accessToken = data['access_token'];
    _tokenExpiration = DateTime.now().add(
      Duration(seconds: data['expires_in']),
    );
  }

  Future<Map<String, dynamic>?> searchFood(String query) async {
    await _authenticate();

    final response = await _dio.get(
      'https://platform.fatsecret.com/rest/server.api',
      queryParameters: {
        'search_expression': query,
        'method': 'foods.search',
        'format': 'json',
      },
      options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
    );
    print('response: ${response.data}');
    return response.data;
  }
}

final fatSecretServiceProvider = Provider<FatSecretService>((ref) {
  final cliendId = '92b3467e0e754b6fad47ea530a014154';
  final clientSecret = 'd113b7e2a7ff49cdbcf43e3859423528';
  return FatSecretService(cliendId: cliendId, clientSecret: clientSecret);
});
