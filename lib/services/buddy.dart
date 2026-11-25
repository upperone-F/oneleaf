import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/buddy.dart';
import '../models/diary.dart';

/// Buddy「小叶」引擎。MVP 的全部产品灵魂都在这里：
/// 1) 系统提示词 —— 决定它是"客服"还是"在乎你的人"
/// 2) 记忆回流 —— 把最近 3 天日记塞进上下文
/// 3) 无 Key 降级 —— 本地规则生成回应，保证任何人都能体验闭环
class BuddyService {
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

  // ---------------- 主动陪伴（不等被 @，Buddy 自己先开口） ----------------

  /// Buddy 主动说一句话。
  /// [trigger] open=刚打开今天 / emotion=检测到情绪 / pause=书写停顿。
  Future<String> proactive({
    required Buddy buddy,
    required String trigger,
    required String content,
    required List<DiaryEntry> recent,
  }) async {
    if (AppConfig.isDemoMode) {
      return _demoProactive(buddy, trigger, content, recent);
    }
    final hint = switch (trigger) {
      'open' => '这是用户今天第一次打开日记，还没开始写。自然地提起前几天写过的一件小事，像朋友先开口，别问“今天怎么样”这种空话。',
      'emotion' => '用户刚写下这些内容，字里有疲惫或烦恼。先站到他这边，轻轻接住，别说教、别“你应该”、别讲大道理。',
      _ => '用户在安静地写日记，刚停下来歇了一下。说一句很短的话，让他知道你在陪着，别打断思路。',
    };
    final prompt = StringBuffer()
      ..writeln(hint)
      ..writeln('用户刚写的：${content.trim().isEmpty ? "（还没开始写）" : content.trim()}');
    if (recent.isNotEmpty) {
      prompt
        ..writeln('前几天写过（可自然提起其中一件）：')
        ..writeln(recent.map((e) => '- ${e.date}：${_snippet(e.content)}').join('\n'));
    }
    prompt..writeln('用「${buddy.name}｜${buddy.role}」的口吻，中文，1-2 句，简短自然。');
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
                {'role': 'user', 'content': prompt.toString()},
              ],
              'temperature': 0.85,
              'max_tokens': 160,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ((data['choices'] as List).first['message']['content'] as String).trim();
      }
    } catch (_) {}
    return _demoProactive(buddy, trigger, content, recent);
  }

  String _demoProactive(
      Buddy buddy, String trigger, String content, List<DiaryEntry> recent) {
    final text = content.trim();
    if (trigger == 'open') {
      if (recent.isNotEmpty) {
        return '昨天你写到「${_snippet(recent.first.content)}」，我一直在想，后来还好吗？';
      }
      return buddy.greeting.isNotEmpty
          ? buddy.greeting
          : '你来啦，我在这儿，慢慢写。';
    }
    if (trigger == 'emotion') {
      if (text.contains('累') || text.contains('困') || text.contains('压力')) {
        return '写到「累」这个字，我想你今天撑了挺久。先歇会儿，我陪你。';
      }
      if (text.contains('烦') || text.contains('气') || text.contains('无语')) {
        return '能感觉到这事挺堵心的。你先说，我听着，不急。';
      }
      return '这一句看着有点沉。不用急着振作，我陪你待一会儿。';
    }
    return '你慢慢写，不用急。我就在这儿。';
  }

  // ---------------- 多 Buddy 对话（各页面示例交互共用） ----------------

  /// 对话页：某个 Buddy 对用户一句话的回应。
  /// 返回 (文本, 卡片类型)，卡片类型为 accounting / drawing / memory 或 null。
  Future<({String text, String? kind})> chatRespond({
    required Buddy buddy,
    required String input,
    required List<DiaryEntry> recent,
    bool proactiveCare = true,
    bool longMemory = true,
    bool moodEcho = true,
  }) async {
    final text = input.trim();
    // 演示模式：本地规则，保证任何 Buddy 都能即时互动
    if (AppConfig.isDemoMode) {
      return _demoChat(buddy, text, recent, longMemory, moodEcho);
    }

    // 真实模式：复用 LLM，注入角色人格
    final prompt = StringBuffer()
      ..writeln('用户说：$text')
      ..writeln('（用「${buddy.name}｜${buddy.role}」的身份和语气回应，中文，简短 2-4 句）');
    if (longMemory && recent.isNotEmpty) {
      prompt..writeln('最近日记：')..writeln(recent.map((e) => '- ${e.content}').join('\n'));
    }
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
                {
                  'role': 'system',
                  'content': _systemPrompt + '\n现在你扮演${buddy.name}，身份是${buddy.role}。${buddy.description}'
                },
                {'role': 'user', 'content': prompt.toString()},
              ],
              'temperature': 0.8,
              'max_tokens': 300,
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (data['choices'] as List).first['message']['content'] as String;
        return (text: content.trim(), kind: null);
      }
    } catch (_) {}
    return _demoChat(buddy, text, recent, longMemory, moodEcho);
  }

  ({String text, String? kind}) _demoChat(
      Buddy buddy, String text, List<DiaryEntry> recent, bool longMemory, bool moodEcho) {
    // 结构化服务卡：记账
    if (buddy.id == 'ben' &&
        (text.contains('记') || text.contains('花') || text.contains('账') || text.contains('钱'))) {
      return (
        text: '帮你把这几笔记下了 👇',
        kind: 'accounting',
      );
    }
    // 结构化服务卡：绘图
    if (buddy.id == 'bagel' &&
        (text.contains('画') || text.contains('颜色') || text.contains('图'))) {
      return (text: '这是今天的心情，给你画下来了。', kind: 'drawing');
    }
    // 记忆引用卡
    if (longMemory &&
        recent.isNotEmpty &&
        (text.contains('还') || text.contains('上次') || text.contains('记得') || text.contains('后来'))) {
      final last = recent.first;
      return (
        text: '你说过「${_snippet(last.content)}」，后来怎么样了？',
        kind: 'memory',
      );
    }

    // 按 Buddy 人设给不同的默认回应
    final replies = <String, List<String>>{
      'xiaoye': [
        '嗯，我在听。你慢慢说，不着急。',
        '听起来今天心里不太轻松，先别急着振作，就这样也挺好。',
        '你说的这些我都记着呢。还有什么想说的吗？',
      ],
      'ben': [
        '把数字报给我，我帮你算清楚。',
        '记账这事交给我，你安心过日子就好。',
      ],
      'tina': [
        '今天天气不错，适合出去走走；要是变天，我会提醒你带伞。',
        '记得看看窗外，天气和你今天的心情一样，会变的。',
      ],
      'bagel': [
        '给我一个词，我就能把它画成颜色。',
        '你的心情是什么形状？我试着画下来。',
      ],
      'bruno': [
        '累了就躺着吧，什么都不做也是一天。',
        '别卷了，歇会儿，我陪你。',
      ],
      'moss': [
        '你为什么会这么想呢？再往里想一层试试。',
        '如果这件事没那么糟，会是什么样？',
      ],
    };
    final pool = replies[buddy.id] ?? replies['xiaoye']!;
    final pick = pool[text.length % pool.length];
    // 情绪关键词：放轻语气
    final echo = (moodEcho &&
            (text.contains('累') || text.contains('烦') || text.contains('难过')))
        ? '听你这么说，我先陪你安静一会儿。'
        : '';
    return (text: '$echo$pick', kind: null);
  }
}
