import '../../core/network/api_client.dart';
import '../../domain/entities/core_health.dart';

abstract class DemoRepository {
  Future<CoreHealth> fetchHealth();
  Future<void> sendPing(String note);
}

class HttpDemoRepository implements DemoRepository {
  HttpDemoRepository(this._client);

  final ApiClient _client;

  @override
  Future<CoreHealth> fetchHealth() async {
    final json = await _client.getJson('/health');
    return CoreHealth.fromJson(json);
  }

  @override
  Future<void> sendPing(String note) async {
    await _client.postJson(
      '/demo/pings',
      body: {'source': 'themis-app', 'note': note},
    );
  }
}
