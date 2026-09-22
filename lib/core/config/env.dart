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

  static String get webProverUrl {
    return dotenv.env['WEB_PROVER_URL'] ?? 'http://localhost:5173/prove';
  }

  /// Rango del delay antes de presentar la credencial de forma anonima.
  /// Configurable para poder acortarlo en una demo, pero con default seguro:
  /// si la presentacion ocurre junto al registro, los timestamps de
  /// `registration_requests` y `presented_credentials` quedan a milisegundos y
  /// permiten asociar la persona con su commitment.
  static Duration get presentationDelayMin =>
      Duration(seconds: _intOr('PRESENTATION_DELAY_MIN_SECONDS', 45));

  static Duration get presentationDelayMax =>
      Duration(seconds: _intOr('PRESENTATION_DELAY_MAX_SECONDS', 180));

  static int _intOr(String key, int fallback) {
    final raw = dotenv.env[key];
    if (raw == null || raw.isEmpty) return fallback;
    return int.tryParse(raw) ?? fallback;
  }
}
