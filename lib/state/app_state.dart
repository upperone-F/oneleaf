import 'package:flutter/foundation.dart';

import '../models/buddy.dart';
import '../models/chat.dart';
import '../services/storage.dart';

/// 全局共享状态（ChangeNotifier，Flutter 自带，零额外依赖）。
/// 管理跨页面的 Buddy 订阅、自建角色、对话、设置开关。
/// 所有变更同步落盘到 StorageService，重启后仍在。
class AppState extends ChangeNotifier {
  final StorageService storage;

  AppState(this.storage) {
    _load();
  }

  static const _kSubscribed = 'subscribed';
  static const _kCustom = 'custom_buddies';
  static const _kChats = 'chats';
  static const _kSettings = 'settings';

  late Set<String> _subscribed;
  late List<Buddy> _custom;
  late Map<String, List<ChatMessage>> _chats;
  late Map<String, bool> _settings;

  void _load() {
    _subscribed = (storage.getStateJson(_kSubscribed) as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
    // 默认订阅小叶 + Ben，保证对话页一打开就有内容
    if (_subscribed.isEmpty) _subscribed = {'xiaoye', 'ben'};

    _custom = storage.getStateList(_kCustom).map(Buddy.fromJson).toList();

    _chats = {};
    final rawChats = storage.getStateJson(_kChats) as Map<String, dynamic>?;
    rawChats?.forEach((key, value) {
      _chats[key] = (value as List<dynamic>)
          .map((e) => ChatMessage(
                id: e['id'] as String,
                isMe: e['isMe'] as bool,
                text: e['text'] as String,
                kind: e['kind'] as String? ?? 'text',
                buddyId: e['buddyId'] as String?,
                time: DateTime.tryParse(e['time'] as String? ?? '') ??
                    DateTime.now(),
              ))
          .toList();
    });

    final rawSettings =
        storage.getStateJson(_kSettings) as Map<String, dynamic>? ?? {};
    _settings = <String, bool>{
      'proactiveCare': true,
      'longMemory': true,
      'moodEcho': true,
      'appLock': false,
      'voice': true,
      ...rawSettings.map((k, v) => MapEntry(k, v as bool)),
    };

    // 给对话页预置示例消息（仅当完全没有聊天记录时）
    if (_chats.isEmpty) _seedChats();
  }

  void _seedChats() {
    _chats['xiaoye'] = [
      ChatMessage(
          id: 's1',
          isMe: true,
          text: '今天项目上线，忙得团团转。'),
      ChatMessage(
          id: 's2',
          isMe: false,
          buddyId: 'xiaoye',
          text: '上线这种日子，光是撑下来就很不容易了。先喘口气，别急着复盘。',
          time: DateTime.now().subtract(const Duration(minutes: 2))),
      ChatMessage(
          id: 's3',
          isMe: false,
          buddyId: 'xiaoye',
          text: '上次你说想去海边，后来去了吗？',
          kind: 'memory',
          time: DateTime.now().subtract(const Duration(minutes: 1))),
    ];
    _persistChats();
  }

  // ---------- Buddy ----------
  List<Buddy> get allBuddies => [...kBuddies, ..._custom];

  List<Buddy> get _allBuddies => allBuddies;

  Set<String> get subscribed => Set.unmodifiable(_subscribed);

  List<Buddy> get subscribedBuddies =>
      _allBuddies.where((b) => _subscribed.contains(b.id)).toList();

  List<Buddy> get customBuddies => List.unmodifiable(_custom);

  bool isSubscribed(String id) => _subscribed.contains(id);

  void toggleSubscribe(String id) {
    if (_subscribed.contains(id)) {
      _subscribed.remove(id);
    } else {
      _subscribed.add(id);
    }
    storage.setStateJson(_kSubscribed, _subscribed.toList());
    notifyListeners();
  }

  void addBuddy(Buddy buddy) {
    _custom.add(buddy);
    _subscribed.add(buddy.id);
    storage.setStateList(
        _kCustom, _custom.map((b) => b.toJson()).toList());
    storage.setStateJson(_kSubscribed, _subscribed.toList());
    notifyListeners();
  }

  Buddy? buddyById(String id) {
    for (final b in _allBuddies) {
      if (b.id == id) return b;
    }
    return null;
  }

  // ---------- 对话 ----------
  List<ChatMessage> chat(String buddyId) => _chats[buddyId] ?? const [];

  void addMessage(String buddyId, ChatMessage msg) {
    final list = _chats.putIfAbsent(buddyId, () => <ChatMessage>[]);
    list.add(msg);
    _persistChats();
    notifyListeners();
  }

  void clearChat(String buddyId) {
    _chats.remove(buddyId);
    _persistChats();
    notifyListeners();
  }

  void _persistChats() {
    storage.setStateJson(
      _kChats,
      _chats.map((key, list) => MapEntry(
          key,
          list
              .map((m) => {
                    'id': m.id,
                    'isMe': m.isMe,
                    'text': m.text,
                    'kind': m.kind,
                    'buddyId': m.buddyId,
                    'time': m.time.toIso8601String(),
                  })
              .toList())),
    );
  }

  // ---------- 设置开关 ----------
  bool setting(String key) => _settings[key] ?? false;

  void toggleSetting(String key) {
    _settings[key] = !(_settings[key] ?? false);
    storage.setStateJson(_kSettings, _settings);
    notifyListeners();
  }
}
