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

  /// Origen de themis-web (CU-10): VoteProofBridge carga `$webBaseUrl/prove`
  /// en un WebView interno para generar la prueba ZK. Mismo criterio por
  /// plataforma que [apiBaseUrl] (ver README: 10.0.2.2 emulador Android,
  /// localhost Chrome/iOS, IP LAN para dispositivo fisico).
  static String get webBaseUrl {
    final value = dotenv.env['WEB_BASE_URL'];

    if (value == null || value.isEmpty) {
      throw StateError(
        'WEB_BASE_URL ausente. Copia .env.example a assets/.env',
      );
    }

    return value;
  }
}
