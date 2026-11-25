import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary.dart';

/// 本地存储。MVP 用 shared_preferences 存 JSON，足够撑起单机单用户。
/// 后期迁移 drift/SQLite 时，只需替换这个类的实现，上层无感。
class StorageService {
  static const _kPrefix = 'diary:';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  DiaryEntry read(String key) {
    final raw = _prefs.getString('$_kPrefix$key');
    if (raw == null) return DiaryEntry(date: key);
    try {
      return DiaryEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return DiaryEntry(date: key);
    }
  }

  Future<void> save(DiaryEntry entry) async {
    await _prefs.setString('$_kPrefix${entry.date}', jsonEncode(entry.toJson()));
  }

  /// 取 [endDate] 之前（不含当天）最近 [count] 天里有内容的日记，按日期从近到远。
  /// 用于「记忆回流」：把最近几天写过的东西塞进 Buddy 的上下文。
  /// 不含当天，避免今天的日记在提示词里重复出现。
  List<DiaryEntry> recentFilled(String endDate, {int count = 3}) {
    final end = DateTime.parse(endDate);
    final result = <DiaryEntry>[];
    for (int i = 1; i < 14 && result.length < count; i++) {
      final day = end.subtract(Duration(days: i));
      final entry = read(dateKey(day));
      if (!entry.isEmpty) result.add(entry);
    }
    return result;
  }

  /// 是否有任何已写的日记（用于判断是否需要「开场白」）。
  bool hasAnyBefore(String endDate) {
    final end = DateTime.parse(endDate);
    for (int i = 1; i < 30; i++) {
      final day = end.subtract(Duration(days: i));
      if (!read(dateKey(day)).isEmpty) return true;
    }
    return false;
  }

  /// 遍历所有已写的日记（日历 / 洞察页用）。
  List<DiaryEntry> allFilled() {
    final result = <DiaryEntry>[];
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(_kPrefix)) continue;
      try {
        final e = DiaryEntry.fromJson(
            jsonDecode(_prefs.getString(key)!) as Map<String, dynamic>);
        if (!e.isEmpty) result.add(e);
      } catch (_) {}
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  // ---------- 通用 KV：保存 Buddy 订阅 / 自建角色 / 设置等轻量状态 ----------
  static const _kState = 'state:';

  Future<void> setStateJson(String key, Object value) =>
      _prefs.setString('$_kState$key', jsonEncode(value));

  Object? getStateJson(String key) {
    final raw = _prefs.getString('$_kState$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> setStateList(String key, List<Map<String, dynamic>> value) =>
      setStateJson(key, value);

  List<Map<String, dynamic>> getStateList(String key) {
    final raw = getStateJson(key);
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
