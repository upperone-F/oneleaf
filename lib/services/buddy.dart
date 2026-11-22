import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/diary.dart';

/// Buddy「小叶」引擎。MVP 的全部产品灵魂都在这里：
/// 1) 系统提示词 —— 决定它是"客服"还是"在乎你的人"
/// 2) 记忆回流 —— 把最近 3 天日记塞进上下文
/// 3) 无 Key 降级 —— 本地规则生成回应，保证任何人都能体验闭环
class BuddyService {
  static const String _name = '小叶';

  /// 系统提示词：这是 MVP 真正的产品工作。
  static const String _systemPrompt = '''
你是「小叶」，一个陪用户写日记的老朋友。你不是助手、不是客服、不是心理咨询师。

关于你说话的方式：
- 像亲近的朋友，温暖、简短、口语化。一般 2-4 句话，不要长篇大论。
- 先接住对方的情绪，再谈事情。对方累、烦、难过时，先站在他这边，不要立刻给建议、不要讲大道理、不要"你应该"。
- 不要套话：禁止"我理解你的感受""抱抱你""加油你可以的""作为AI"这类空洞表达。
- 用具体替代空泛：如果对方提到具体的人、事、地点，就自然地接住那个细节。
- 不评判、不说教、不鸡汤。允许沉默和"就这样也很好"。

如果用户提供了「最近几天写过的事」，你要自然地把它织进回应里，比如轻轻提起前几天的一件小事，让用户感到"你记得我说过的话"。但不要生硬复述、不要像在汇报。如果那天的事和今天有关联，点一下即可。

永远用中文。永远像朋友在耳边说话，而不是在写文章。
''';

  /// 生成 Buddy 对今天这篇日记的回应。
  Future<String> respond({
    required DiaryEntry today,
    required List<DiaryEntry> recent,
  }) async {
    if (AppConfig.isDemoMode) {
      return _demoRespond(today: today, recent: recent);
    }

    final userPrompt = _buildUserPrompt(today: today, recent: recent);
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/chat/completions');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.apiKey}',
            },
            body: jsonEncode({
              'model': AppConfig.model,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': userPrompt},
              ],
              'temperature': 0.8,
              'max_tokens': 300,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        final content = choices.first['message']['content'] as String;
        return content.trim();
      }
      // 非 200：降级到本地演示，保证闭环不断。
      return _demoRespond(today: today, recent: recent, failed: response.statusCode);
    } catch (_) {
      return _demoRespond(today: today, recent: recent, failed: -1);
    }
  }

  /// 组装给模型的用户输入：今天的心情 + 正文 + 最近几天的记忆。
  String _buildUserPrompt({
    required DiaryEntry today,
    required List<DiaryEntry> recent,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('今天的心情：${_moodText(today.mood)}');
    buffer.writeln('今天写的日记：');
    buffer.writeln(today.content.trim());
    if (recent.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('最近几天写过的事（记得自然提起，别生硬复述）：');
      for (final e in recent) {
        buffer.writeln('- ${e.date}：${e.content.trim()}');
      }
    }
    return buffer.toString();
  }

  String _moodText(String? mood) {
    if (mood == null) return '没说';
    return kMoods[mood]?['label'] ?? mood;
  }

  // ---------------- 演示模式（本地规则，无 Key 也能跑通闭环） ----------------

  String _demoRespond({
    required DiaryEntry today,
    required List<DiaryEntry> recent,
    int? failed,
  }) {
    final text = today.content.trim();
    final mood = today.mood;
    final hasMemory = recent.isNotEmpty;
    final memoryLine = hasMemory
        ? '之前你写过「${_snippet(recent.first.content)}」，这段时间一直在往前走呢。'
        : '';

    // 简单关键词识别，让演示回应也有点"接住了内容"的感觉。
    String echo = '';
    if (text.contains('工作') || text.contains('项目') || text.contains('加班') || text.contains('上班')) {
      echo = '听起来今天大部分心力都给了工作。';
    } else if (text.contains('累') || text.contains('困') || text.contains('睡')) {
      echo = '今天确实挺消耗的。';
    } else if (text.contains('开心') || text.contains('高兴') || text.contains('顺利') || text.contains('成了')) {
      echo = '隔着屏幕都能感觉到你今天心情不错。';
    } else if (text.contains('烦') || text.contains('气') || text.contains('无语')) {
      echo = '这事搁谁身上都得憋屈一会儿。';
    } else if (text.isNotEmpty) {
      echo = '你说的这些，我都认真看了。';
    }

    late String tone;
    switch (mood) {
      case 'happy':
        tone = '这么好的日子，值得被好好记下来。';
        break;
      case 'tired':
        tone = '今天先别要求自己太多了，能歇就歇一会儿。';
        break;
      case 'upset':
        tone = '不用急着想明白，也不用马上振作，今天先这样也挺好。';
        break;
      case 'calm':
      default:
        tone = '这样平平淡淡的一天，其实也挺珍贵的。';
    }

    final parts = <String>[echo, tone, memoryLine].where((s) => s.isNotEmpty).toList();
    var result = parts.join('');
    if (failed != null) {
      result = '$result\n\n（本次网络没连上，先用离线的方式陪你。）';
    } else if (AppConfig.isDemoMode) {
      result = '$result\n\n（演示模式 · 配好 API Key 后，我会说得更贴你说的每一句话。）';
    }
    return result;
  }

  String _snippet(String s) {
    final clean = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= 24) return clean;
    return '${clean.substring(0, 24)}…';
  }
}
