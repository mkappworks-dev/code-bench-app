abstract interface class ProvidersRepository {
  Future<String?> readApiKey(String provider);
  Future<void> writeApiKey(String provider, String key);
  Future<void> deleteApiKey(String provider);
  Future<String?> readOllamaUrl();
  Future<void> writeOllamaUrl(String url);
  Future<void> deleteOllamaUrl();
  Future<String?> readAnthropicTransport();
  Future<void> writeAnthropicTransport(String value);
  Future<void> deleteAnthropicTransport();
  Future<String?> readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url);
  Future<void> deleteCustomEndpoint();
  Future<String?> readCustomApiKey();
  Future<void> writeCustomApiKey(String key);
  Future<void> deleteCustomApiKey();
  Future<void> deleteAllSecureStorage();
}
