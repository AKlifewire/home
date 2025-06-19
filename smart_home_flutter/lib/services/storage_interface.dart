abstract class StorageInterface {
  Future<void> saveValue(String key, String value);
  Future<String?> getValue(String key);
  Future<void> deleteValue(String key);
  Future<void> deleteAll();
}
