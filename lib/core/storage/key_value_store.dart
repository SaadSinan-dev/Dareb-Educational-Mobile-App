/// Non-sensitive local preferences only; never store authentication tokens here.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}
