import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static const _envPath = 'assets/.env';

  static Future<void> load() async {
    await dotenv.load(fileName: _envPath);
  }

  static String get apiBaseUrl {
    final value = dotenv.env['API_BASE_URL'];

    if (value == null || value.isEmpty) {
      throw StateError(
        'API_BASE_URL ausente. Copia .env.example a assets/.env',
      );
    }

    return value;
  }
}
