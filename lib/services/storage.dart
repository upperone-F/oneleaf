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
}
