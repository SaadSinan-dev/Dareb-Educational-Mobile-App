import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'support/memory_store.dart';

void main() {
  test('theme and language persist and restore', () async {
    final store = MemoryStore();
    final first = AppPreferencesCubit(store);
    await first.setThemeMode(ThemeMode.dark);
    await first.setLanguage('en');
    expect(first.state.themeMode, ThemeMode.dark);
    expect(first.state.languageCode, 'en');
    await first.close();

    final restored = AppPreferencesCubit(store);
    await restored.restore();
    expect(restored.state.themeMode, ThemeMode.dark);
    expect(restored.state.languageCode, 'en');
    await restored.setThemeMode(ThemeMode.system);
    await restored.setLanguage('ar');
    expect(restored.state.themeMode, ThemeMode.system);
    expect(restored.state.languageCode, 'ar');
    await restored.close();
  });

  test('invalid stored preferences fall back to Arabic and light', () async {
    final store = MemoryStore();
    await store.write(
      AppPreferencesCubit.storageKey,
      '{"theme":"unknown","language":"xx"}',
    );
    final preferences = AppPreferencesCubit(store);
    await preferences.restore();
    expect(preferences.state.themeMode, ThemeMode.light);
    expect(preferences.state.languageCode, 'ar');
    await preferences.close();
  });
}
