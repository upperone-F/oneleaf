/// 一条日记。MVP 阶段所有数据存在本机，不上云。
class DiaryEntry {
  /// 日期键，格式 yyyy-MM-dd
  final String date;
  final String content;

  /// 心情：happy / calm / tired / upset，未选为 null
  final String? mood;

  /// Buddy 的回应
  final String? buddyReply;
  final DateTime updatedAt;

  DiaryEntry({
    required this.date,
    this.content = '',
    this.mood,
    this.buddyReply,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isEmpty => content.trim().isEmpty;

  DiaryEntry copyWith({
    String? content,
    String? mood,
    String? buddyReply,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      date: date,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      buddyReply: buddyReply ?? this.buddyReply,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'content': content,
        'mood': mood,
        'buddyReply': buddyReply,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> j) => DiaryEntry(
        date: j['date'] as String,
        content: (j['content'] as String?) ?? '',
        mood: j['mood'] as String?,
        buddyReply: j['buddyReply'] as String?,
        updatedAt:
            DateTime.tryParse((j['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

/// 四档心情的展示信息。
const Map<String, Map<String, String>> kMoods = {
  'happy': {'label': '开心', 'emoji': '☀️'},
  'calm': {'label': '平静', 'emoji': '🍃'},
  'tired': {'label': '累', 'emoji': '🌙'},
  'upset': {'label': '烦', 'emoji': '🌧️'},
};

/// 把日期格式化为 yyyy-MM-dd（本地时区，不用 intl，保持依赖最少）。
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
