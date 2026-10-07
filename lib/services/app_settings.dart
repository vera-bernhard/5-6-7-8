import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Settings of the app itself, stored on the device like the songs.
class AppSettings {
  static const String _boxName = 'app_settings';
  static const String _languageKey = 'language';
  static Box<dynamic>? _box;

  /// The language chosen in the app, or null to follow the system language.
  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  static Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    final code = _box!.get(_languageKey);
    locale.value = code is String ? Locale(code) : null;
  }

  static Future<void> setLocale(Locale? value) async {
    locale.value = value;
    final box = _box;
    if (box == null) return;
    if (value == null) {
      await box.delete(_languageKey);
    } else {
      await box.put(_languageKey, value.languageCode);
    }
  }
}
