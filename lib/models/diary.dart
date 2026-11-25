/// 日记里的一段 @Buddy 对话：用户 @ 后说的话 + Buddy 的回应，默认保留在日记里。
class DiaryThread {
  final String id;
  final String buddyId;
  final String question;
  final String reply;
  final DateTime time;

  DiaryThread({
    required this.id,
    required this.buddyId,
    required this.question,
    required this.reply,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'buddyId': buddyId,
        'question': question,
        'reply': reply,
        'time': time.toIso8601String(),
      };

  factory DiaryThread.fromJson(Map<String, dynamic> j) => DiaryThread(
        id: j['id'] as String,
        buddyId: j['buddyId'] as String,
        question: j['question'] as String,
        reply: j['reply'] as String,
        time: DateTime.tryParse(j['time'] as String? ?? '') ?? DateTime.now(),
      );
}

/// 一条日记。MVP 阶段所有数据存在本机，不上云。
class DiaryEntry {
  /// 日期键，格式 yyyy-MM-dd
  final String date;
  final String content;

  /// 心情：happy / calm / tired / upset，未选为 null
  /// （日记页已不再展示心情选择器，但对话情绪感知 / 日历等模块仍会用到）
  final String? mood;

  /// 当天封面在图库中的序号；null 表示按日期自动取一张
  final int? coverIndex;

  /// 内嵌在这篇日记里的 @Buddy 对话（默认保留，可单条删除）
  final List<DiaryThread> threads;

  /// Buddy 的回应（旧字段，保留兼容；新交互请用 threads）
  final String? buddyReply;
  final DateTime updatedAt;

  DiaryEntry({
    required this.date,
    this.content = '',
    this.mood,
    this.coverIndex,
    this.threads = const [],
    this.buddyReply,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isEmpty => content.trim().isEmpty && threads.isEmpty;

  static const Object _unset = Object();

  DiaryEntry copyWith({
    String? content,
    String? mood,
    Object? coverIndex = _unset,
    List<DiaryThread>? threads,
    String? buddyReply,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      date: date,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      coverIndex: identical(coverIndex, _unset)
          ? this.coverIndex
          : coverIndex as int?,
      threads: threads ?? this.threads,
      buddyReply: buddyReply ?? this.buddyReply,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'content': content,
        'mood': mood,
        'coverIndex': coverIndex,
        'threads': threads.map((t) => t.toJson()).toList(),
        'buddyReply': buddyReply,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> j) => DiaryEntry(
        date: j['date'] as String,
        content: (j['content'] as String?) ?? '',
        mood: j['mood'] as String?,
        coverIndex: j['coverIndex'] as int?,
        threads: (j['threads'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => DiaryThread.fromJson(e))
            .toList(),
        buddyReply: j['buddyReply'] as String?,
        updatedAt:
            DateTime.tryParse((j['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

/// 四档心情的展示信息（保留给对话/洞察等模块使用，日记页已不再展示心情选择器）。
const Map<String, Map<String, String>> kMoods = {
  'happy': {'label': '开心', 'emoji': '☀️'},
  'calm': {'label': '平静', 'emoji': '🍃'},
  'tired': {'label': '累', 'emoji': '🌙'},
  'upset': {'label': '烦', 'emoji': '🌧️'},
};

/// 把日期格式化为 yyyy-MM-dd（本地时区，不用 intl，保持依赖最少）。
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
