import 'dart:convert';

import 'settings_storage_stub.dart'
    if (dart.library.io) 'settings_storage_io.dart'
    if (dart.library.js_interop) 'settings_storage_web.dart'
    as settings_storage;

class AppSettings {
  const AppSettings({
    required this.currencyCode,
    required this.expenseCategories,
    this.userName = '',
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      currencyCode: 'COP',
      expenseCategories: AppSettingsService.defaultExpenseCategories,
      userName: '',
    );
  }

  final String currencyCode;
  final List<String> expenseCategories;
  final String userName;

  AppSettings copyWith({
    String? currencyCode,
    List<String>? expenseCategories,
    String? userName,
  }) {
    return AppSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      userName: userName ?? this.userName,
    );
  }

  Map<String, Object?> toJson() => {
    'currencyCode': currencyCode,
    'expenseCategories': expenseCategories,
    'userName': userName,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['expenseCategories'];
    final categories = AppSettingsService.normalizeCategories(
      rawCategories is List
          ? rawCategories.whereType<String>()
          : AppSettingsService.defaultExpenseCategories,
    );

    return AppSettings(
      currencyCode: json['currencyCode'] is String
          ? json['currencyCode'] as String
          : 'COP',
      expenseCategories: categories,
      userName:
          json['userName'] is String &&
              AppSettingsService.isValidUserName(json['userName'] as String)
          ? AppSettingsService.normalizeUserName(json['userName'] as String)
          : '',
    );
  }
}

class AppSettingsService {
  const AppSettingsService();

  static const defaultExpenseCategories = [
    'Comidaaaa',
    'Comida para bichos',
    'Transportes',
    'Cineeeee',
    'Compraaaas',
    'Aceo Personal',
    'Resivos xd',
    'Otros',
    subscriptionCategory,
  ];

  static const subscriptionCategory = 'Suscripción';

  static final _userNamePattern = RegExp(
    r'^\p{L}+(?:[ -]\p{L}+)*$',
    unicode: true,
  );

  static String normalizeUserName(String userName) {
    return userName.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool isValidUserName(String userName) {
    final normalized = normalizeUserName(userName);
    return normalized.isNotEmpty && _userNamePattern.hasMatch(normalized);
  }

  static const _foodCategoryAliases = {
    'comidas': 'Comidaaaa',
    'comida': 'Comidaaaa',
    'comida para gatos': 'Comida para bichos',
    'comida para los bichos': 'Comida para bichos',
  };

  static const _canonicalFoodCategories = {'comidaaaa', 'comida para bichos'};

  static String normalizeCategory(String category) {
    return _foodCategoryAliases[category.trim().toLowerCase()] ?? category;
  }

  static List<String> normalizeCategories(Iterable<String> categories) {
    final normalized = <String>[];
    final seenFoodCategories = <String>{};
    for (final category in categories) {
      final canonical = normalizeCategory(category);
      final key = canonical.trim().toLowerCase();
      if (_canonicalFoodCategories.contains(key) &&
          !seenFoodCategories.add(key)) {
        continue;
      }
      normalized.add(canonical);
    }
    return normalized;
  }

  Future<AppSettings> load() async {
    final contents = await settings_storage.readSettings();
    if (contents == null) return AppSettings.defaults();

    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El archivo de ajustes no es válido.');
    }
    final parsed = AppSettings.fromJson(decoded);
    final settings = parsed.copyWith(
      expenseCategories: _withRequiredCategories(parsed.expenseCategories),
    );
    final rawCategories = decoded['expenseCategories'];
    if (rawCategories is List) {
      final savedCategories = rawCategories.whereType<String>().toList();
      if (!_sameCategories(savedCategories, settings.expenseCategories)) {
        await save(settings);
      }
    }
    return settings;
  }

  Future<void> save(AppSettings settings) async {
    final userName = normalizeUserName(settings.userName);
    if (userName.isNotEmpty && !isValidUserName(userName)) {
      throw ArgumentError.value(
        settings.userName,
        'userName',
        'Usa solo letras españolas y espacios entre nombres.',
      );
    }
    final normalizedSettings = settings.copyWith(
      expenseCategories: _withRequiredCategories(settings.expenseCategories),
      userName: userName,
    );
    await settings_storage.writeSettings(
      jsonEncode(normalizedSettings.toJson()),
    );
  }

  Future<void> saveUserName(AppSettings settings, String userName) async {
    final normalized = normalizeUserName(userName);
    if (!isValidUserName(normalized)) {
      throw ArgumentError.value(
        userName,
        'userName',
        'Usa solo letras españolas y espacios entre nombres.',
      );
    }
    await save(settings.copyWith(userName: normalized));
  }

  Future<void> reset() async {
    await settings_storage.deleteSettings();
  }

  bool _sameCategories(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  List<String> _withRequiredCategories(Iterable<String> categories) {
    final normalized = normalizeCategories(categories);
    if (!normalized.any(
      (category) =>
          category.trim().toLowerCase() == subscriptionCategory.toLowerCase(),
    )) {
      normalized.add(subscriptionCategory);
    }
    return normalized;
  }
}
