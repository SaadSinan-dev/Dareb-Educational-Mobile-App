import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/core/storage/key_value_store.dart';

class AppPreferencesState {
  const AppPreferencesState({
    this.themeMode = ThemeMode.light,
    this.languageCode = 'ar',
    this.ready = false,
    this.saveFailed = false,
  });

  final ThemeMode themeMode;
  final String languageCode;
  final bool ready;
  final bool saveFailed;

  AppPreferencesState copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? ready,
    bool? saveFailed,
  }) => AppPreferencesState(
    themeMode: themeMode ?? this.themeMode,
    languageCode: languageCode ?? this.languageCode,
    ready: ready ?? this.ready,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}

/// Application appearance and language preferences; never stores credentials.
class AppPreferencesCubit extends Cubit<AppPreferencesState> {
  AppPreferencesCubit(this.store) : super(const AppPreferencesState());

  static const storageKey = 'tamkeen.preferences.v1';
  final KeyValueStore store;
  Future<void> _writes = Future<void>.value();
  int _generation = 0;
  AppPreferencesState _persisted = const AppPreferencesState();

  Future<void> restore() async {
    final operation = ++_generation;
    try {
      final raw = await store.read(storageKey);
      if (isClosed || operation != _generation) return;
      if (raw == null) {
        _persisted = const AppPreferencesState(ready: true);
        emit(_persisted);
        return;
      }
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic>) throw const FormatException();
      final theme = switch (value['theme']) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
      final language = value['language'] == 'en' ? 'en' : 'ar';
      _persisted = AppPreferencesState(
        themeMode: theme,
        languageCode: language,
        ready: true,
      );
      emit(_persisted);
    } catch (_) {
      if (!isClosed && operation == _generation) {
        _persisted = const AppPreferencesState(ready: true);
        emit(_persisted);
      }
    }
  }

  Future<void> setThemeMode(ThemeMode value) =>
      _save(state.copyWith(themeMode: value, ready: true, saveFailed: false));

  Future<void> setLanguage(String languageCode) {
    if (languageCode != 'ar' && languageCode != 'en') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    return _save(
      state.copyWith(
        languageCode: languageCode,
        ready: true,
        saveFailed: false,
      ),
    );
  }

  Future<void> _save(AppPreferencesState next) async {
    if (isClosed) return;
    final operation = ++_generation;
    emit(next);
    final raw = jsonEncode({
      'theme': next.themeMode.name,
      'language': next.languageCode,
    });
    final write = _writes.then((_) => store.write(storageKey, raw));
    _writes = write.catchError((Object _) {});
    try {
      await write;
      if (isClosed) return;
      if (operation == _generation) _persisted = next;
    } catch (_) {
      if (!isClosed && operation == _generation) {
        emit(_persisted.copyWith(saveFailed: true, ready: true));
      }
    }
  }
}
