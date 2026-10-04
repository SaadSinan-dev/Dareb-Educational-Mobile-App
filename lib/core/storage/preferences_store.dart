import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamkeen2/core/storage/key_value_store.dart';

/// Device preferences for non-sensitive preview data only.
class PreferencesStore implements KeyValueStore {
  const PreferencesStore();
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);
  @override
  Future<void> write(String key, String value) async {
    final stored = await (await SharedPreferences.getInstance()).setString(
      key,
      value,
    );
    if (!stored) throw StateError('Preference write failed');
  }

  @override
  Future<void> remove(String key) async {
    final stored = await (await SharedPreferences.getInstance()).remove(key);
    if (!stored) throw StateError('Preference removal failed');
  }
}
